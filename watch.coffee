fs = require 'fs'

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

  name: ->
    @path.split(Dir::separator).slice(-1)[0]

  constructor: (path, stat) ->
    @path = path
    @stat = stat

class Dir

  Dir::separator = if process.platform.match(/^win/)? then '\\' else '/'

  constructor: (path, stat) ->
    @files = {}
    @path = path
    @stat = stat

  name: ->
    @path.split(Dir::separator).slice(-1)[0]

  read: ->
    @files[name] = File::new(@path, name) for name in fs.readdirSync(@path)
    this

  invoke: (event, data...) ->
    if (tmp = @[event](data...))
      Watcher::[event](tmp...)

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
    delete @files[oldname]
    [File::path(@path, oldname), @files[newname].path, @files[newname]]

  change: (filename) ->
    if !@files[filename].stat.isDirectory() and (tmp = File::new @path, filename) and @files[filename].stat.ctime.getTime() isnt tmp.stat.ctime.getTime()
        @files[filename].stat = tmp.stat
        return [@files[filename]]
    false

  filenames: -> name for name, file of @files
  filepaths: -> file.path for name, file of @files
  directories: -> file for name, file of @files when file.stat.isDirectory()

  watch: (dir) ->

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
        subdir.watch File::new(subdir.path).read()

class Watcher

  handlers:
    create: ->
    remove: ->
    change: ->
    rename: ->

  delay: 50
  pause: false
  step: 0

  constructor: (root = 'app') ->
    @root = File::new root
    unless @root.stat.isDirectory()
      throw new Error('Directory was expected')
    this

  watch: ->
    dir = File::new(@root.path).read()
    @root.watch dir
    unless @pause
      setTimeout( =>
        @watch()
        @step++
      , @delay)

  stop: ->
    @pause = true

  start: ->
    @step = 0
    @pause = false
    @watch()

  on: (event, handler) ->
    Watcher::[event] = =>
      handler(arguments...) unless @step is 0
    this

return Watcher

