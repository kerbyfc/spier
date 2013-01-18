fs = require 'fs'
mm = require 'minimatch'

Array.prototype.diff = (arr) ->
  this.filter(
    (i) -> 
      return !(arr.indexOf(i) > -1)
  )

class File

  File::stat = (parts...) ->
    fs.statSync(File::path(parts...))

  File::path = (parts...) ->
    parts.join Dir::separator

  File::new = (path, stat = File::stat path) ->
    if stat.isDirectory() then new Dir(path, stat) else new File(path, stat)

  constructor: (path, stat) ->
    @path = path
    @name = @path.split(Dir::separator).slice(-1)[0]
    @stat = stat



class Dir

  Dir::separator = if process.platform.match(/^win/)? then '\\' else '/'

  constructor: (path, stat) ->
    @path = path
    @files = {}
    @ignore = []
    @step = 0
    @options = {}
    @name = @path.split(Dir::separator).slice(-1)[0]
    @stat = stat
    @existed = []
    @cache = {}
    @empty = []

  __ignore: (path) ->
    !( @options.ignore? and !!@options.ignore.test(path) )

  __filter: (path) ->
    @options.filter? and !!@options.filter.test(path)

  __pattern: (path) ->
    @options.pattern? and !!mm(path, @options.pattern, {matchBase: true})

  suitable: (filename) ->

    path = File::path(@path, filename)
    stat = File::stat(path)
#
#    checks =
#      i: @__ignore(path)
#      p: @__pattern(path)
#      f: @__filter(path)
#
#    for k, v of checks
#      checks[k.toUpperCase()] = v
#
##    console.log checks
#
#    types =
#      '*': (a, b) -> a and b
#      '+': (a, b) -> a or b
#
##    console.log types
#
#    naming =
#      f: 'filter'
#      F: 'Filter'
#      i: 'ignore'
#      I: 'Ignore'
#      p: 'pattern'
#      P: 'Pattern'
#
#    comparision = true
#    type = types['*']
#    for i in @options.rules.split('')
#      if i in ['P', 'I', 'F', 'p','i','f']
##        console.log " >>>>>>>>>>>>>>>>>>>", comparision
#        comparision = type(comparision, checks[i])
##        console.log naming[i], path, @options[naming[i].toLowerCase()], comparision
#        if i in ['P', 'I', 'F']
#          comparision = comparision or stat.isDirectory()
##          console.log "############", comparision
#      else
#        type = types[i]



    if stat.isDirectory() or Spier.comparator.compare(path)

      @cache[filename] = File::new(path, stat)

      if @options.skip_empty isnt undefined and @cache[filename].stat.isDirectory() and @cache[filename].read(@options).current.length is 0
        @empty.push filename
        return false

      true

    else

      unless stat.isDirectory()
        @ignore.push filename

      false

  read: () =>
    unless @step is options.step
      @current = []
      @empty = []
      @current.push filename for filename in fs.readdirSync(@path) when filename not in @ignore and @suitable(filename)
      @step = options.step
#      console.log "READ", @path, @filenames()
    this

  invoke: (event, data...) ->
    if (tmp = @[event](data...))
      Spier::[event](tmp...)

  create: (filename) ->
    unless filename in @empty
      @files[filename] = if @cache[filename]? then ( (d) -> d)(@cache[filename]) else File::new(File::path(@path, filename))
      return [@files[filename]]
    false

  remove: (filename) ->
    tmp = (=> @files[filename])()
    delete @files[filename]
    [tmp]

  rename: (oldname, newname) ->
    @files[newname] = @files[oldname]
    @files[newname].path = File::path @path, newname
    @files[newname].name = newname
    delete @files[oldname]
    [File::path(@path, oldname), @files[newname].path, @files[newname]]

  change: (filename) ->
    if !@files[filename].stat.isDirectory() and (tmp = File::new(File::path @path, filename)) and @files[filename].stat.ctime.getTime() isnt tmp.stat.ctime.getTime()
      @files[filename].stat = tmp.stat
      return [@files[filename]]
    false

  filenames: ->
    name for name, file of @files

  filepaths: (filenames = @filenames()) ->
    File::path @path, filename for filename in filenames

  directories: ->
    file for name, file of @files when file.stat.isDirectory()

  compare: ->

    existed = @existed
    current = @current

#    console.log "CACHE", existed, '<->', current

    created = current.diff existed
    removed = existed.diff current

    if removed.length is created.length and created.length is 1
      @invoke 'rename', removed[0], created[0]
    else
      @invoke 'create', file for file in created
      @invoke 'remove', file for file in removed
      @invoke 'change', file for file in existed.diff removed

    subdirs = @directories()

    @existed = ( (c) -> c)(current)

#    console.log "CACHE =", @current

    if subdirs.length > 0
      for subdir in subdirs
        subdir.read(@options).compare()


class Comparator

  comparisions: []

  map:
    i: 'ignore'
    f: 'filter'
    p: 'pattern'

  combos:
    '*': (a, b) -> a and b
    '+': (a, b) -> a or b

  constructor: (rules = 'p+i*f', data = {}) ->

    @rules = rules.toLowerCase()
    @data = data

#    high = rules.match(/\w{1}\*\w{1}/)              // TODO
#    if high? and high.index > 0
#      @rules = high[0] + rules.slice(0, high.index).

    combo = @combos['*']
    for char in @rules.split('')
      if char.match(/\w/)?
        @comparisions.push combo: combo, fn: @['_' + @map[char]], type: @map[char] if @data[@map[char]] isnt undefined
      else
        combo = @combos[char]

    console.log @comparisions

  compare: (path, result = true) ->

    for comparision in @comparisions
      result = comparision.combo( result, comparision.fn(path) )
      console.log comparision.type.toUpperCase(), @data[comparision.type], 'in', path, comparision.fn(path)

    console.log "> include", path, result

  _ignore: (str) =>
    !( @data.ignore? and !@data.ignore.test(str) )

  _filter: (str) =>
    @data.filter? and !!@data.filter.test(str)

  _pattern: (str) =>
    @data.pattern? and !!mm(str, @data.pattern, {matchBase: true})

class Spier

  handlers:
    create: ->
    remove: ->
    change: ->
    rename: ->

  delay: 50
  pause: false

  options:
    step: 1
    ignore_flags: ''
    filter_flags: ''

  shutdown: (msg) ->
    console.log msg
    process.exit(0)

  isRegExp: (rg) ->
    rg = rg.toString() if typeof rg is 'object'
    rg = "/#{rg}/" unless rg.slice(0,1)[0] is '/' and rg.slice(-1)[0] is '/'
    rg.match( /\/.*\/(.?)$/ )?

  constructor: (root = null, options = {}) ->

    unless root?
      @shutdown 'Specify directory path for spying. Use spy --help'

    try
      stat = File::stat root
    catch e
      @shutdown root + ' doesn`t exists'

    unless stat.isDirectory()
      @shutdown root + ' is not a directory'

    @setup options

    @scope = File::new root, stat

  setup: (options) ->

    compares = {}

    for excerpt in ['ignore', 'filter']

      if options[excerpt] and options[excerpt]?

        if @isRegExp(options[excerpt])

          compares[excerpt] = if typeof options[excerpt] is 'string'
            new RegExp(options[excerpt], @options[excerpt + '_flags'])
          else
            options[excerpt]

        else
          @shutdown excerpt + ' is not a valid regexp'

        delete options[excerpt]

    if options.pattern and options.pattern?
      compares.pattern = options.pattern
      delete options.pattern

    Spier.comparator = new Comparator(options.rules ?= null, compares)

    @options[k]=v for k,v of options

    this

  lookout: ->

    @scope.read().compare()
    unless @pause
      setTimeout( =>
        @lookout()
        @options.step++
      , @delay)


  pause: ->
    @pause = true

  spy: ->
    @step = 0
    @pause = false
    @lookout()

  on: (event, handler) ->
    Spier::[event] = =>
      handler(arguments...) unless @options.step is 1 and @options.existing is undefined
    this

module.exports = Spier

