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

  File::new = (parts...) ->
    path = File::path parts...
    stat = File::stat path
    if stat.isDirectory() then new Dir(path, stat) else new File(path, stat)

  constructor: (path, stat) ->
    @path = path
    @name = @path.split(Dir::separator).slice(-1)[0]
    @stat = stat

class Dir

  Dir::separator = if process.platform.match(/^win/)? then '\\' else '/'

  constructor: (path, stat) ->
    @files = {}
    @path = path
    @name = @path.split(Dir::separator).slice(-1)[0]
    @stat = stat

  add: (filename, options) ->

    path = File::path(@path, filename)

    match =
      ignore: options.ignore? and options.ignore.test path
      filter: options.filter? and options.filter.test path
      pattern: options.pattern? and mm(path, options.pattern, matchBase: true)
      directory: File::stat(path).isDirectory()

    if match.directory or ( !match.ignore and (match.filter or match.pattern) )
      @files[filename] = File::new(path)

  read: (options) ->
    @add filename, options for filename in fs.readdirSync(@path)
    this

  invoke: (event, data...) ->
    if (tmp = @[event](data...))
      Spier::[event](tmp...)

  create: (filename) ->
    @files[filename] = File::new @path, filename
    [@files[filename]]

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
    if !@files[filename].stat.isDirectory() and (tmp = File::new @path, filename) and @files[filename].stat.ctime.getTime() isnt tmp.stat.ctime.getTime()
        @files[filename].stat = tmp.stat
        return [@files[filename]]
    false

  filenames: ->
    name for name, file of @files

  filepaths: ->
    file.path for name, file of @files

  directories: ->
    file for name, file of @files when file.stat.isDirectory()

  compare: (dir, options) ->

    existed = @filenames()
    current = dir.filenames()

    created = current.diff existed
    removed = existed.diff current

    if removed.length is created.length and created.length is 1
      @invoke 'rename', removed[0], created[0]
    else
      @invoke 'create', file for file in created
      @invoke 'remove', file for file in removed
      @invoke 'change', file for file in existed.diff removed

    subdirs = @directories()
    if subdirs.length > 0
      for subdir in subdirs
        subdir.compare File::new(subdir.path).read(options), options

class Spier

  handlers:
    create: ->
    remove: ->
    change: ->
    rename: ->

  delay: 50
  pause: false
  step: 0

  options:
    ignore: null
    ignore_flags: ''
    filter: null
    filter_flags: ''
    pattern: null

  shutdown: (msg) ->
    console.log msg
    process.exit(0);

  constructor: (root = null, options = {}) ->

    unless root?
      @shutdown 'Specify directory path for spying. Use spy --help'

    @setup options

    for excerpt in ['ignore', 'filter']
      @options[excerpt] = new RegExp(@options[excerpt], @options[excerpt + '_flags']) if @options[excerpt]?

    try
      @scope = File::new root
    catch err
      @shutdown err.message

    unless @scope.stat.isDirectory()
      @shutdown "#{root} is not a directory"

    this

  setup: (options) ->
    @options[key] = val for key, val of options

  lookout: ->
    try
      reality = File::new(@scope.path).read(@options)
      @scope.compare reality, @options
      unless @pause
        setTimeout( =>
          @lookout()
          @step++
        , @delay)
    catch err
      @shutdown err.message unless @options.silence?

  pause: ->
    @pause = true

  spy: ->
    @step = 0
    @pause = false
    @lookout()

  on: (event, handler) ->
    Spier::[event] = =>
      handler(arguments...) unless @step is 0 and @options.existing is undefined
    this

module.exports = Spier

