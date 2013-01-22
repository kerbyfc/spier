fs = require 'fs'
minimatch = require 'minimatch'

Array.prototype.diff = (arr) ->
  this.filter(
    (i) -> 
      return !(arr.indexOf(i) > -1)
  )

class File

  File::stat = (path) ->
    fs.statSync(path)

  File::path = (parts...) ->
    parts.join Dir::separator

  File::new = (path, options = {}) ->
    stat = File::stat path
    if stat.isDirectory() then new Dir(path, stat, options) else new File(path, stat)

  constructor: (path, stat) ->
    @path = path
    @name = @path.split(Dir::separator).slice(-1)[0]
    @stat = stat

class Dir

  Dir::separator = if process.platform.match(/^win/)? then '\\' else '/'

  options:
    pattern: null
    ignore: null

  constructor: (path, stat, options) ->
    @path = path
    @stat = stat
    @options = options
    @name = @path.split(Dir::separator).slice(-1)[0]
    @setup()

  setup: =>
    @files = {}
    @index =
      current: []
      existed: []
      ignored: []

  check: (filename) ->

    path = File::path @path, filename

    if @isInIgnore(path)
      @ignore(filename)
    else if !@matchPattern(path)
      @ignore(filename)
    else
      true

  isInIgnore: (path) ->
#    console.log "? #{path} matches (#{@options.pattern}) -> #{(@options.pattern? and !@options.pattern.test path)}"
    @options.pattern? and !@options.pattern.test path

  matchPattern: (path) ->
#    console.log "? #{path} in ignore (#{@options.ignore}) -> #{(@options.ignore? and @options.ignore.test path)}"
    @options.ignore? and @options.ignore.test path

  ignore: (filename) ->
    unless File::stat(File::path @path, filename).isDirectory()
#      console.log '--ignore', File::path(@path, filename)
      @index.ignored.push filename
      false
    else
      true


  read: () =>
    @index.current = []
    @index.current.push filename for filename in fs.readdirSync(@path) when filename not in @index.ignored and (filename in @index['existed'] or @check(filename))
    this

  invoke: (event, data...) ->
    if (tmp = @[event](data...))
#     TODO
#      console.log Spier.instances[@options.id].handlers[event].toString()
      Spier.instances[@options.id].handlers[event](tmp...)

  create: (filename) ->
    @files[filename] = File::new File::path(@path, filename), @options
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

    existed = @index.existed
    current = @index.current

    created = current.diff existed
    removed = existed.diff current

#    console.log @path
#    console.log 'EXITED', existed
#    console.log 'CURRENT', current
#    console.log 'CREATED', created
#    console.log 'REMOVED', removed

    if removed.length is created.length and created.length is 1
      @invoke 'rename', removed[0], created[0]
    else
      @invoke 'create', file for file in created
      @invoke 'remove', file for file in removed
      @invoke 'change', file for file in existed.diff removed

    subdirs = @directories()

    @index.existed = ((c)->c) @index.current

    if subdirs.length > 0
      for subdir in subdirs
        subdir.read(@options).compare()

class Spier

  delay: 50
  pause: false
  step: 1
  handlers: {}

  options:
    id: null
    root: null
    ignore: null
    pattern: null
    matchBase: false
    existing: false
    dot: true

  @instances = {}

  # create new Spier instance
  @spy = ->
    new Spier(arguments...).spy()

  # configuring
  constructor: (options) ->
    @configure(options) if options?

  spy: (options) ->

    # just start if instance have been already created
    return @start() if @options.id?

    @configure(options) if options?

    # check nessesary params
    unless @options.root?
      @shutdown 'Specify directory path for spying. Use spy --help'

    # check file access TODO use file system utilities for this
    try
      stat = File::stat @options.root
    catch e
      @shutdown @options.root + ' doesn`t exists'

    unless stat.isDirectory()
      @shutdown @options.in + ' is not a directory'

    # create root folder object
    @scope = new Dir @options.root, stat, @options

    # create instance id
    @options.id = Math.random().toString().substr(2)

    # register this instance
    Spier.instances[@options.id] = this

    @start()

    return this

  # specify instance options
  configure: (options = null) ->

    # options object must be an instance of Object class
    unless typeof options is 'object'
      @shutdown "Options object missing"

    # setup matchbase flag before regexp generation
    @options.matchBase = options.matchBase || false

    # validate option value if it is pattern
    for option, value of options
      @options[option] = unless option in ['pattern', 'ignore'] then value else @regexp(value, option)

    return this

  # validate pattern and create regexp
  regexp: (pattern, name) ->

    # just return RegExp object if he was passed
    if pattern instanceof RegExp or pattern is null
      return pattern

    # create RegExp from string
    else if typeof pattern is 'string'

      return null unless pattern.length

      # try to create RegExp from string
      try
        # if string looks like regexp
        if pattern.match( /^\/.*\/([igm]*)?$/ )? and (fIndex = pattern.lastIndexOf('/'))
          regexp = new RegExp pattern.substr( 1, fIndex-1), pattern.substring(++fIndex)
          console.log pattern.substr( 1, fIndex-1)
          console.log regexp
          return regexp

        # create with minimatch
        else
          # new Minimatch object
          return minimatch.makeRe pattern, {matchBase: @options.matchBase, dot: @options.dot}

      # something went wrong
      catch e
        @shutdown "Pattern `#{pattern}` is invalid. #{e.message}"

    # invalid pattern type
    else
      @shutdown "Option `#{name}` must be an instance of String or RegExp. #{typeof pattern} given"

  # look for directory changes
  lookout: ->

    @scope.read().compare()

    # repeat after delay
    unless @pause
      @timeout = setTimeout( =>
        @lookout()
        @options.step++
      , @delay)

  # stop watching
  pause: ->
    @timeout = clearTimeout(@timeout) || null
    @pause = true

  # start watching loop
  start: ->
    @step = if @options.existing then 1 else 0
    @pause = false
    @lookout()

  # register event handler for event such as create/rename/remove/change
  on: (event, handler) ->
    @handlers[event] = =>
      handler(arguments...) if @step > 0
    this

  shutdown: (msg) ->
    console.log msg
    process.exit(0)

module.exports = Spier


# REFACTORING TO
# • Command line
#   - spy [for <minimatch pattern/regexp string> pattern] in <string> directory path [ignoring <minimatch pattern/regexp string> pattern]
#
# • Api
#   - spier = Spier.spy( for: pattern, ignoring: pattern, in: directory )

#
#
#
#
#
