fs = require 'fs'

Array.prototype.diff = (arr) ->
  this.filter(
    (i) -> 
      return !(arr.indexOf(i) > -1)
  )

class Watcher

  struct: []
  cache: {}

  changes: {}
  renamed: {}

  depth: 0
  step: 0

  handlers: 
    create: ->
    remove: ->
    change: ->
    rename: ->

  # Интервал между перезапуском
  speed: 200

  constructor: (@root = 'app') ->
    @watch(@root)

  # Склеить путь
  path: (parts...) ->
    parts.join('/')

  exists: (depth = @depth, files = []) ->
    files.push key.slice (key.lastIndexOf('/') + 1) for key, val of @struct[depth]; files

  subpaths: (depth = @depth, parent_path, paths = []) ->
    paths.push path for path, file of @struct[depth]; paths

  files: (dir) ->
    fs.readdirSync(dir)

  dirs: (files = []) ->
    files.push file for file, stat of @struct[@depth] when stat.isDirectory(); files  

  on: (action, handler) ->
    @handlers[action] = handler
    this

  subs: (depth = @depth, path, files = []) ->
    files.push file for file in @exists(depth) when file.indexOf(path) is 0
    files

  watch: (dir) ->
    
    @struct[@depth] ?= {}
    @cache[dir] = @depth

    # # console.log "DEPTH", @depth

    # Обнулить данные об изменениях для текущего прохода
    @changes = 
      change: []
      remove: []
      create: []
      rename: []

    current = @files(dir)
    # # console.log "current FILES", current
    # # console.log "exists FILES", @exists()

    # watch for created
    created = current.diff @exists()
    # # console.log "created FILES", created

    for file in created
      path = @path(dir, file)
      @changes['create'].push [path, @stat path]

    # - - - - - - - - - - - - - - - 

    if @step > 0

      # watch for removed
      removed = @exists().diff current
      # # console.log "removed FILES", removed 

      for file in removed
        path = @path(dir, file)
        @changes['remove'].push [path]

      for file in current.diff(removed)
        @check @path(dir, file)

      # watch for renamed
      if @changes['remove'].length == @changes['create'].length and @changes['remove'].length is 1
        
        prev = @changes['remove'][0]
        curr = @changes['create'][0]

        @changes['rename'].push [prev[0], curr[0], curr[1]]

        @changes['remove'] = []
        @changes['create'] = []

    # - - - - - - - - - - - - - - - 

    for type, actions of @changes
      for action in actions
        results = @[type](action...)
        if results and @step > 0
          @handlers[type](results...) 

      # # console.log @changes

    subdirs = @dirs()

    # # console.log 'sub-dirs', subdirs

    if subdirs.length

      @depth++

      for dir in subdirs
        @watch dir

      @depth--

    @renamed = {}

    @step++

  change: (path, prev, curr) ->
    console.log '- change:', path
    @add path, @depth, curr
    [path, prev, curr]

  remove: (path, depth = @depth, removed = null) ->
    
    console.log '- remove', path unless removed? or @renamed?
    
    prev = @get(path) || removed

    @unset path, depth

    if prev
    
      # -------------------------

      if prev.isDirectory()

        if @renamed[@depth]?
          dir = if @depth isnt depth
            @renamed[@depth][1] + path.slice(path.lastIndexOf '/')
          else
            @renamed[@depth][1]
          files = @files(dir) 
        else
          dir = path
          files = @subpaths (depth+1), dir

        # console.log "REMOVE SUBS OF " + path, files

        for file in files
          unless dir is path
            stat = @add @path(dir, file), (depth + 1) 
            @remove @path(path, file), (depth + 1), stat
          else
            @remove file, (depth + 1), (@get file, (depth + 1))
      # -------------------------

      [path, prev]
    
    else 
      false

  create: (path) ->
    console.log '-', (if @step is 0 then 'watch' else 'create:'), path
    [path, @add path]

  rename: (prevPath, currPath, curr) ->
    console.log '- rename', prevPath, '->', currPath
    @renamed[@depth] = [prevPath, currPath]
    @remove prevPath
    @add currPath
    [prevPath, currPath, curr]

  get: (path, depth = @depth) ->
    unless @struct[depth]?
      false
    else
      @struct[depth][path] || false

  add: (path, depth = @depth, stat = null) ->
    stat = @stat(path) unless stat?
    @struct[depth][path] = stat
    stat

  unset: (path, depth = @depth) ->
    if @struct[depth][path]?
      delete @struct[depth][path] 

  stat: (path) ->
    fs.statSync(path)

  check: (path) ->
  
    if (prev = @get(path)) and not prev.isDirectory()

      curr = @stat(path)

      if curr.ctime.getTime() isnt prev.ctime.getTime()
        @changes['change'].push [path, prev, curr]


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


