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

  File::new = (path, options = {}, parent) ->
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

  constructor: (path, stat, options, parent = null) ->
    @path = path
    @stat = stat
    @options = options
    @parent = parent
    @name = @path.split(Dir::separator).slice(-1)[0]
    @setup()

  setup: =>
    @step = 0
    @subdirs = false
    @changed = null
    @files = {}
    @cache = {}
    @index =
      current: []
      existed: []
      ignored: []
      subdirs: []
    @history = {}

  cleanup: ->
    @index.existed = ((c)->c) @index.current
    @index.current = []
    @index.subdirs = []
    @cache = {}
  
  cached: (filename) ->
    @cache[filename] || File::new( File::path @path, filename, this )

  filepath: (filename) ->
    File::path @path, filename

  check: (filename) ->

    path = @filepath filename

    if @isInIgnore(path)
      return @ignore(filename) # false
    
    stat = File::stat(path)

    if !@matchPattern(path) and !stat.isDirectory()
      @ignore(filename) # false
    else
      @cache[filename] = if stat.isDirectory()
        new Dir(path, stat, @options, this) # !false (true)
      else
        new File(path, stat) # !false (true)

  isInIgnore: (path) ->
    if @options.debug
      console.log "#{path} #{if (@options.ignore? and @options.ignore.test path) then 'WAS' else 'WASN`T'} ignored by #{@options.ignore} pattern"
    @options.ignore? and @options.ignore.test path

  matchPattern: (path) ->
    if @options.debug
      console.log "#{path} #{if (!@options.pattern? or @options.pattern.test path) then 'WAS' else 'WASN`T'} processed by #{@options.pattern} pattern"
    !@options.pattern? or @options.pattern.test path

  ignore: (filename) ->
    @index.ignored.push filename
    false

  read: =>
    tmpStat = File::stat(@path)
    @changed = if @stat.atime.getTime() isnt tmpStat.atime.getTime() or @changed is null
      @stat = tmpStat
      @cleanup()
      @add filename for filename in fs.readdirSync(@path) when filename not in @index.ignored
      true
    else
      false
    @step++
    this

  add: (filename) ->
    if filename in @index.existed or @check(filename)
      @index.current.push filename

  archive: (filename, event, file) ->
    @history[filename] ?= []
    @history[filename].push [event, file]
    @history[filename].shift() if @history[filename].length > 20

  trigger: (event, file) ->
    Spier.instances[@options.id].handlers[event](file) if @step
    @archive(file.name, event, file)

  invoke: (event, data...) ->
    if (file = @[event](data...))
      @trigger event, file

  create: (filename, file = false) ->

    @files[filename] = file || @cached(filename)
    
    if @files[filename].stat.isDirectory()
      @index.subdirs.push filename
      @subdirs = true

    if @files[filename].stat.isDirectory() and (!@options.folders or @options.skipEmpty)
      false
    
    else

      if @options.skipEmpty and @parent? and !@parent.history[@name]

        @parent.trigger 'create', this

        # console.log "CREATE ", @name, 'for', @parent.path, @parent.history[@name]
        
        # если принято не добавлять пустые директории а это директория не добавлять сразу
        unless @files[filename].stat.isDirectory()
          @files[filename]
        else
          false
      
      else
        @files[filename]

  remove: (filename) ->
    tmp = (=> @files[filename])()
    delete @files[filename]
    tmp

  rename: (oldname, newname) ->
    @files[newname] = @files[oldname]
    @files[newname].path = File::path @path, newname
    @files[newname].name = newname
    @files[newname].lastname = oldname
    delete @files[oldname]
    @files[newname]

  change: (filename) ->

    curr = File::stat @filepath(filename)

    if curr.isDirectory() and (@files[filename].stat.atime.getTime() isnt curr.atime.getTime() or @files[filename].subdirs)

      # console.log ">> DIR CHANGED", @files[filename].path, @files[filename].stat.atime

      @files[filename].stat = curr
      @index.subdirs.push filename
      false

    else if !curr.isDirectory() and @files[filename].stat.ctime.getTime() isnt curr.ctime.getTime()

      @files[filename].stat = curr
      @files[filename]

    else
      false

  filenames: ->
    name for name, file of @files

  filepaths: (filenames = @filenames()) ->
    @filepath filename for filename in filenames

  directories: ->
    file for name, file of @files when file.stat.isDirectory()

  compare: ->

    if @changed

      existed = @index.existed
      current = @index.current

      created = current.diff existed
      removed = existed.diff current

      # console.log @path, 'EXITED', existed, 'CURRENT', current, 'CREATED', created, 'REMOVED', removed

      if removed.length is created.length and created.length is 1
        @invoke 'rename', removed[0], created[0]
      else
        @invoke 'create', file for file in created
        @invoke 'remove', file for file in removed
        @invoke 'change', file for file in existed.diff removed

    for subdir in @index.subdirs
      @files[subdir].read().compare()

class Spier

  delay: 200
  pause: false

  memory: 10.0
  handlers: {}

  options:
    id: null
    root: null
    ignore: null
    pattern: null
    matchBase: false
    existing: false
    dot: true
    folders: false
    skipEmpty: false


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

    @options.skipEmpty = false unless @options.folders

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
        if pattern.match( /^r\/.*\/([igm]*)?$/ )? and (fIndex = pattern.lastIndexOf('/'))
          return new RegExp pattern.substr( 2, fIndex-3), pattern.substring(fIndex+1)

        # create with minimatch
        else
          # new Minimatch object
          return minimatch.makeRe pattern, {matchBase: @options.matchBase, dot: @options.dot}

      # something went wrong
      catch e
        @shutdown "Pattern `#{pattern}` is invalid. #{e.message}"

    # invalid pattern type
    else
      @shutdown "Option `#{name}` must be an instance of String or RegExp. <#{typeof pattern}> #{pattern} given"

  # look for directory changes
  lookout: ->

    @scope.read().compare()

    # repeat after delay
    unless @pause
      @timeout = setTimeout( =>
        @lookout()
        @step++
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
    @handlers[event] = handler
    this

  shutdown: (msg) ->
    console.log msg
    process.exit(0)

module.exports = Spier
