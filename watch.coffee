fs = require 'fs'

Array.prototype.diff = (arr) ->
  this.filter(
    (i) -> 
      return !(arr.indexOf(i) > -1)
  )

class Cacheable

  _step: -1
  _cache: {}
  _actual: {}

  cache: (key, data = null) ->
    unless data?
      @_cache[key]
    else
      @_step[key] = Watcher::step
      @_cache[key] = data

  actual: (cache) ->
    @_step[cache]? and @_step[cache] is Watcher::step

class File extends Cacheable

  File::stat = (path) ->
    fs.statSync(path)

  File::path = (parts...) ->
    parts.join Dir::separator

  constructor: (@dir, @name) ->
    @path = @dir + Dir::separator + @name
    @stat = File::stat @path

class Dir extends Cacheable

  Dir::separator = if process.platform.match(/^win/)? then '\\' else '/'

  constructor: (@path) ->
    @files = (new File(@path, filename) for filename in fs.readdirSync(@path)) || []

  get: (attr) ->
    unless @actual(attr)
      @cache attr, (file[attr] for file in @files)
    else
      @cache attr

  filenames: ->
    @get 'name'

  filepaths: ->
    @get 'path'

  sub: ->
    file.path for file in @files when file.stat.isDirectory()

class Slice extends Cacheable

  constructor: (depth) ->
    @depth = depth
    @files = {}
    @events = {}

  existing: (dir) ->
    (file.name for path, file of @files when file.path.indexOf dir is 0) || []

  get: (path) ->
    @files[path]

  invoke: (event, data...) ->
    @[event](data...)
    @events[event] = data

  create: (file, silence = false) ->
    @files[file.path] = file
    console.log 'create', file.path unless silence

  remove: (file, silence = false) ->
    delete @files[file.path]
    console.log 'remove', file.path unless silence

  rename: (prev, curr) ->
    @create curr, true
    @remove prev, true
    console.log 'rename', prev.path, 'to', curr.path

#  cleanup: (dir) ->
#
##    parent = @watcher.slice (@depth-1)
##    renamed = parent.events['renaming']
##    removed = parent.events['removing']
##
##    if renamed?
##      for data in renamed
##        for file in @existing(dir.path)
##          if file.indexOf data[0] is 0
##            prev =
##            curr = file.replace(data[0].dir, new File data[1].path
##          @invoke 'renaming', data[0], @file.replace(data[0], data[1])

  diff: (dir) ->

    console.log "->", dir.path

    @events = {}

    existing = @existing(dir.path)
    created = dir.filenames().diff(existing)

    if Watcher::step > 0

      removed = existing.diff dir.filenames()

      if removed.length is created.length and created.length is 1

        @invoke 'rename', @get(File::path dir.path, removed[0]), (new File(dir.path, created[0]))

      else

        @invoke 'create', new File(dir.path, file) for file in created
        @invoke 'remove', @get(File::path dir.path, file) for file in removed

    else

      @invoke 'create', new File(dir.path, file) for file in created


class Watcher

#  rename: (prevPath, currPath, curr) ->
#    console.log '- rename', prevPath, '->', currPath
#    @renamed[@depth] = [prevPath, currPath]
#    @slice().remove prevPath
#    @slice().create currPath
#    [prevPath, currPath, curr]
#
#  remove: (file, depth = @depth, removed = null) ->
#
#    console.log '- remove', file.path unless removed? or @renamed?
#
#    prev = @get(path) || removed
#
#    @unset path, depth
#
#    if prev
#
#      # -------------------------
#
#      if prev.isDirectory()
#
#        if @renamed[@depth]?
#          dir = if @depth isnt depth
#            @renamed[@depth][1] + path.slice(path.lastIndexOf '/')
#          else
#            @renamed[@depth][1]
#          files = @files(dir)
#        else
#          dir = path
#          files = @subpaths (depth+1), dir
#
#        # console.log "REMOVE SUBS OF " + path, files
#
#        for file in files
#          unless dir is path
#            stat = @add @path(dir, file), (depth + 1)
#            @remove @path(path, file), (depth + 1), stat
#          else
#            @remove file, (depth + 1), (@get file, (depth + 1))
#      # -------------------------
#
#      [path, prev]
#
#    else
#      false
#
#  change: (path, prev, curr) ->
#    console.log '- change:', path
#    @add path, @depth, curr
#    [path, prev, curr]
#
#  create: (path) ->
#    console.log '-', (if @step is 0 then 'watch' else 'create:'), path
#    [path, @add path]
#
#  get: (path, depth = @depth) ->
#    unless @struct[depth]?
#      false
#    else
#      @struct[depth][path] || false
#
#  add: (path, depth = @depth, stat = null) ->
#    stat = @stat(path) unless stat?
#    @struct[depth][path] = stat
#    stat
#
#  unset: (path, depth = @depth) ->
#    if @struct[depth][path]?
#      delete @struct[depth][path]



  check: (path) ->

    if (prev = @get(path)) and not prev.isDirectory()

      curr = @stat(path)

      if curr.ctime.getTime() isnt prev.ctime.getTime()
        @changes['change'].push [path, prev, curr]

  Watcher::step = 0

  _struct: []

  depth: 0

  handlers:
    create: ->
    remove: ->
    change: ->
    rename: ->

  # rescan interval
  speed: 1000

  # specify watched directory
  constructor: (@root = 'app') ->
    @watch(@root)

  slice: ->
    @_struct[@depth] || null

  watch: (path) ->

    unless @slice()?
      @_struct[@depth] = new Slice(@depth)

    dir = new Dir path

    @slice().diff dir

    if dir.sub().length

      @depth++

      for sub in dir.sub()

        @watch sub

      @depth--

    Watcher::step++




#    # watch for created
#    for path in dir.paths().diff @struct[@depth].keys()
#      @changes['create'].push [path, new File File::stat path]
#
#    unless @first()
#
#      # watch for removed
#      removed = cached.diff dir.filenames
#      # # console.log "removed FILES", removed
#
#      for file in removed
#        path = @path(dir, file)
#        @changes['remove'].push [path]
#
#      for file in current.diff(removed)
#        @check @path(dir, file)
#
#      # watch for renamed
#      if @changes['remove'].length == @changes['create'].length and @changes['remove'].length is 1
#
#        prev = @changes['remove'][0]
#        curr = @changes['create'][0]
#
#        @changes['rename'].push [prev[0], curr[0], curr[1]]
#
#        @changes['remove'] = []
#        @changes['create'] = []
#
#    # - - - - - - - - - - - - - - -
#
#    for type, actions of @changes
#      for action in actions
#        results = @[type](action...)
#        if results and @step > 0
#          @handlers[type](results...)
#
#    # # console.log @changes
#
#    subdirs = @dirs()
#
#    # # console.log 'sub-dirs', subdirs
#
#    if subdirs.length
#
#      @depth++
#
#      for dir in subdirs
#        @watch dir
#
#      @depth--
#
#    @renamed = {}
#
#

#  cached: (depth = @depth, files = []) ->
#    file.name for file in files
#
#  subpaths: (depth = @depth, parent_path, paths = []) ->
#    paths.push path for path, file of @struct[depth]; paths
#
#  files: (dir) ->
#    fs.readdirSync(dir)
#
#  dirs: (files = []) ->
#    files.push file for file, stat of @struct[@depth] when stat.isDirectory(); files
#
  on: (action, handler) ->
    @handlers[action] = handler
    this
#
#  subs: (depth = @depth, path, files = []) ->
#    files.push file for file in @exists(depth) when file.indexOf(path) is 0
#    files
#





  run: ->
    @watch(@root)
    setInterval( =>
      @watch(@root)
      # # console.log 'struct -', @struct
      # # console.log '==============================================================================================='
    , @speed)
    

watcher = new Watcher('testdir')

watcher.on 'create', (path, file) ->
  console.log '>>> CREATED', path

watcher.on 'remove', (path, file) ->
  console.log '>>> REMOVED', path

watcher.on 'change', (path, prev, curr) ->
  console.log '>>> CHANGED', path

watcher.on 'rename', (path, newpath, file) ->
  console.log '>>> RENAMED from ' + path + ' to ' + newpath

watcher.run()


