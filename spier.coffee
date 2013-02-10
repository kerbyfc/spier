fs = require 'fs'
rexp = require 'rexp'
path = require 'path'
_ = require 'underscore'

class sFile

  @new = ( _path, opts = {} ) ->    
    if ( stat = Spier.stat _path ) and ( opts = _.extend {}, opts, stat:stat, path:_path, name:path.basename(_path) ) and stat.isDirectory() then new sDir opts else new sFile opts

  constructor: ( opts = {} ) ->
    _.extend @, opts

global.sFile = sFile

class sDir

  defaults: files:{}, cache:{}, step:{}

  constructor: ( opts = {} ) ->
    @setup(opts)
    @index = {}
    @index.ignored = []
    @index.current = []
    @index.existed = []
    
  setup: (opts) -> 
    @[prop] = val for prop, val of _.extend @defaults, opts

  reindex: ->
    @index.existed = _.clone @index.current; @index.current = []

  clearCache: (stat) ->
    [@cache, @stat] = [{}, stat]

  cleanup: (stat = @stat) ->
    @reindex @clearCache(stat)
    
  get: (filename) ->
    @cache[filename] || sFile.new (path.join @path, filename), this
  
  isChanged: ->
    if @lazy and (stat = Spier.stat @path) and stat.atime.getTime() isnt @stat.atime.getTime() then @cleanup(stat) else false

  goDown: ->
    @files[file].compare() for file in @index.files when file.stat.isDirectory()

  filenames: ->
    name for name, file of @files

  paths: (filenames = @filenames()) ->
    path.join @path, filename for filename in filenames

  directories: ->
    file for name, file of @files when file.stat.isDirectory()

  read: ->
    @add filename for filename in fs.readdirSync(@path) when filename not in @index.ignored; this

  add: (filename) ->
    @index.current.push filename if filename in @index.existed or @check(filename)

  check: ->
    if @isChanged() or !_.size @files then @compare() else @goDown()

  compare: ->
    if @involveRename() then @invoke 'rename', @step.rename[0], @step.create[0] else @handle @step.change = _.difference @index.existed, @step.remove

  handle: ->
    @invoke event, file for file in files for event, files of @step; @goDown()
          
  involveRename: -> # TODO here is error
    @difference().remove.length is @step.created.length and @step.created.length is 1

  difference: ->
    @read().step = create: _.difference( @index.current, @index.existed ), remove: _.difference( @index.existed, @index.current )  

  isInIgnore: (_path) ->
    @options.ignore? and @options.ignore.test _path

  matchPattern: (_path) ->
    !@options.target? or @options.target.test _path

  ignore: (filename) ->
    @index.ignored.push filename; false

  # REFACTOR ---- 

  check: (filename) ->

    _path = path.join @path, filename

    if @isInIgnore(_path)
      return @ignore(filename) # false
    
    stat = Spier.stat _path

    if !@matchPattern(_path) and !stat.isDirectory()
      @ignore(filename) # false
    else
      @cache[filename] = if stat.isDirectory()
        new sDir options: @options, path:_path, stat:stat, parent:this # !false (true)
      else
        new File(_path, stat) # !false (true)

  # REFACTOR ---- 

  archive: (filename, event, file) ->
    @history[filename] ?= []
    @history[filename].push [event, file]
    @history[filename].shift() if @history[filename].length > 20

  trigger: (event, file) ->
    Spier.instances[@options.id].handlers[event](file) if @step
    @archive(file.name, event, file)

  invoke: (event, data...) ->
    if (file = @["_#{event}"](data...))
      console.log 'trigger', event, file.name
      @trigger event, file

  _create: (filename, file = false) ->

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

  _remove: (filename) ->
    tmp = (=> @files[filename])()
    delete @files[filename]
    tmp

  _rename: (oldname, newname) ->
    @files[newname] = @files[oldname]
    @files[newname].path = path.join @path, newname
    @files[newname].name = newname
    @files[newname].lastname = oldname
    delete @files[oldname]
    @files[newname]

  _change: (filename) ->

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

global.sDir = sDir

# handler noop
class sNoop
  
  constructor: (e) -> 
    @e = e
  
  fire: (file) => 
    console.log "#{@event} #{`file.stat.isDirectory() ? 'directory' : 'file'`} #{file.path}" 

class Spier

  # STATIC

  # create new Spier instance
  @spy = (target, options)->
    new Spier(options).spy(target)

  @stat = (slices...) ->
    fs.statSync(path.join slices...)

  @shutdown = (msg = 'Unknown error') -> 
    console.error msg; process.exit(0)
  
  # PUBLIC

  defaults: 
    ignore: null 
    target: null

  # flags specify searching strategy and event handling
  flags: { strict:false, primary:false, folders:false, dotfiles: false, noops: false }

  # lookout loop delay
  delay: 50

  # instantiating
  constructor: ( opts = {}, @options = {}, @handlers = {} ) ->
    @configure opts
    @handlers[event] = (new sNoop event).fire for event in ['create', 'remove', 'rename', 'change'] if @options.noops 
        
  # options setup
  configure: ( opts ) ->
    @setup option, value for option, value of _.extend {}, @flags, @defaults, opts; this

  setup: ( option, value ) ->
    @options[ option ] = unless option in [ 'ignore', 'target' ] then value else rexp.create value, {dot: @options.dotfiles}

  spy: ( target = './**/*' ) ->
    @setup 'target', target; @start()

  # create root folder object, start watching loop
  start: ( @pause = false ) ->
    @scope = sFile.new '.', options:@options; @lookout()

  # stop watching
  stop: ( @pause = true ) ->
    @timeout = clearTimeout(@timeout) || null; this

  # look for directory changes after delay
  lookout: ->
    unless @pause
      @timeout = setTimeout => 
        @scope.compare()
        @lookout()
      , @delay
    this

  # register event handler for event such as create/rename/remove/change
  on: (event, handler) ->
    @handlers[event] = handler; this

  off: (event) -> 
    delete @handlers[event];

module.exports = Spier
