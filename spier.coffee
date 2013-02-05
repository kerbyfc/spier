fs = require 'fs'
rexp = require 'rexp'
path = require 'path'
_ = require 'underscore'

Array.prototype.diff = (arr) ->
  this.filter(
    (i) -> 
      return !(arr.indexOf(i) > -1)
  )

class sFile

  @new = (_path, opts = {}) ->    
    if (stat = Spier.stat _path) and (opts = _.extend {}, opts, stat:stat, name: path.basename _path) and stat.isDirectory() then new Dir(opts) else new File(opts)

  constructor: (opts = {}) ->
    _.extend @, opts

global.sFile = sFile

class sDir

  constructor: (opts = {}) ->
    _.extend @, opts
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

  cleanup: (stat = null) ->
    @index.existed = ((c)->c) @index.current
    @index.current = []
    @index.subdirs = []
    @cache = {}
    @stat = stat if stat?
  
  cached: (filename) ->
    @cache[filename] || sFile.new (path.join @path, filename), this

  check: (filename) ->

    _path = path.join @path, filename

    if @isInIgnore(_path)
      return @ignore(filename) # false
    
    stat = Spier.stat _path

    if !@matchPattern(_path) and !stat.isDirectory()
      @ignore(filename) # false
    else
      @cache[filename] = if stat.isDirectory()
        new Dir(_path, stat, @options, this) # !false (true)
      else
        new File(_path, stat) # !false (true)

  isInIgnore: (_path) ->
    if @options.debug
      console.log "#{_path} #{if (@options.ignore? and @options.ignore.test _path) then 'WAS' else 'WASN`T'} ignored by #{@options.ignore} pattern"
    @options.ignore? and @options.ignore.test _path

  matchPattern: (path) ->
    if @options.debug
      console.log "#{_path} #{if (!@options.target? or @options.target.test _path) then 'WAS' else 'WASN`T'} processed by #{@options.target} pattern"
    !@options.target? or @options.target.test _path

  ignore: (filename) ->
    @index.ignored.push filename
    false

  read: =>
    tmpStat = Spier.stat @path
    @changed = if @stat.atime.getTime() isnt tmpStat.atime.getTime() or @changed is null or true
      @cleanup(tmpStat)
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
    @files[newname].path = path.join @path, newname
    @files[newname].name = newname
    @files[newname].lastname = oldname
    delete @files[oldname]
    @files[newname]

  change: (filename) ->

    curr = Spier.stat @path, filename

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

  paths: (filenames = @filenames()) ->
    path.join @path, filename for filename in filenames

  directories: ->
    file for name, file of @files when file.stat.isDirectory()

  compare: ->

    if @changed

      existed = @index.existed
      current = @index.current

      created = current.diff existed
      removed = existed.diff current

      console.log @path, 'EXISTED', existed, 'CURRENT', current, 'CREATED', created, 'REMOVED', removed

      if removed.length is created.length and created.length is 1
        @invoke 'rename', removed[0], created[0]
      else
        @invoke 'create', file for file in created
        @invoke 'remove', file for file in removed
        @invoke 'change', file for file in existed.diff removed

    console.log "SUBDIRS", @index.subdirs

    for subdir in @index.subdirs
      @files[subdir].read().compare()

global.sDir = sDir

class Spier

  # STATIC

  # handler noop
  @noop = (@e) ->
    @fire = (file) -> console.log "#{@e} #{`file.stat.isDirectory() ? 'directory' : 'file'`} #{file.path}"

  # create new Spier instance
  @spy = (target, options)->
    new Spier(options).spy(target)

  @stat = (slices...) ->
    fs.statSync(path.join slices...)
  
  # PUBLIC

  defaults: 
    ignore: null 
    target: null

  # flags specify searching strategy and event handling
  flags: { strict:false, primary:false, folders:false, dotfiles: false, noops: false }

  # lookout loop delay
  delay: 50

  # instantiating
  constructor: ( opts = {} ) ->
    @configure( opts )

  # options setup
  configure: ( opts, @options = {} ) ->
    @setup options, value for option, value of _.extend {}, @defaults, @flags, opts; this

  setup: ( option, value ) ->
    @options[ option ] = unless option in [ 'ignore', 'target' ] then value else rexp.create value, {dot: @options.dotfiles}

  spy: ( target = './**/*' ) ->
    @setup 'target', @seton(target); @start()

  seton: ( target ) -> 
    @root = target.substr 0, target.indexOf( '/' ) if typeof target is 'string'; target

  # stop watching
  stop: ( @pause = true ) ->
    @timeout = clearTimeout(@timeout) || null

  # create root folder object, start watching loop
  start: ( @pause = false ) ->
    @scope = new Dir( @options.root, Spier.stat @root, @options ).read().compare(); @lookout()

  # look for directory changes after delay
  lookout: ->
    @timeout = setTimeout( => 
      @lookout @scope.read().compare()
    ,@delay); this

  # register event handler for event such as create/rename/remove/change
  on: (event, handler) ->
    @handlers[event] = handler; this

  shutdown: (msg) ->
    console.error msg; process.exit(0)    

module.exports = Spier
