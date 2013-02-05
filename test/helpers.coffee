global.fs = require 'fs'
global.path = require 'path'
global.sinon = require 'sinon'
global.exec = require('child_process').exec
global.shld = require 'should'
global.glob = require 'glob'
global.wrench = require 'wrench'
global._ = require 'underscore'

global.TEST_DIR = __dirname
global.TEMP_DIR = path.join __dirname, 'tmp'
global.SPEC_DIR = path.join TEST_DIR, 'specs'

global.Spier = require '../spier.coffee'


global.__cleanup = (done) ->
  
  try
    wrench.rmdirSyncRecursive TEMP_DIR
  
  try
    fs.mkdir TEMP_DIR, '0777', =>
      done()


class TestEngine

  constructor: (opts = {}) ->

    @timeouts = []
    @delay = 100

    opts = _.extend {}, opts
    @spier = new Spier(opts).spy(TEMP_DIR)
    @callbacks = {}

    @on event, ((file) -> undefined) for event in ['create', 'rename', 'remove', 'change']
    
  on: (event, callback = -> undefined) =>
    @callbacks[event] = callback
    @["$#{event}"] = sinon.spy(@callbacks[event])
    @spier.on event, @["$#{event}"]

  noop: ->

  test: (fn) ->
    @timeouts.push setTimeout => 
      fn()
    , @delay + 60

  destroy: ->
    for timeout in @timeouts
      timeout = (clearTimeout timeout) || null
    @callbacks = null
    @spier.stop()
    delete @spier

  tmp: ->
    path.join TEMP_DIR, path.join(arguments...)

  getArgs: (event, call = 0) ->
    @["$#{event}"][call]
    
  invoke: (action, args...) ->
    setTimeout =>
      @["_#{action}"](args...)
    , @delay
    
  then: (delay = parseInt @spier.delay * 1.5) ->
    @delay += delay; this

  create: (file, fn = @noop) ->
    @invoke 'create', file, fn; this

  remove: (file, fn = @noop) ->
    @invoke 'remove', file, fn; this

  change: (file, fn = @noop) -> 
    @invoke 'change', file, fn; this

  rename: (oldname, newname, fn = @noop) ->
    @invoke 'rename', oldname, newname, fn; this

  _remove: (_path, fn, __path = @tmp(_path)) ->
    stat = fs.statSync __path
    if stat.isDirectory()
      wrench.rmdirSyncRecursive path.join(__path, _file), (err, data) => 
        if err?
            console.log " > DIR #{__path} NOT REMOVED"
          else
            console.log " > DIR #{__path} REMOVED"
          fn()
    else
      fs.unlink __path, (err, data) =>
        if err?
          console.log " > FILE #{__path} NOT REMOVED"
        else
          console.log " > FILE #{__path} REMOVED"
        fn()

  _create: (_path, fn, __path = @tmp(_path)) ->
    if __path.substring(__path.lastIndexOf('/') + 2).indexOf('.') > -1
      fs.writeFile __path, "#{new Date().toString()}\n", (err, data) =>
        if err?
          console.log " > FILE #{__path} NOT CREATED"
        else
          console.log " > FILE #{__path} CREATED"
        fn()  
    else
      fs.mkdir __path, '0777', (err, data) => 
        if err?
          console.log " > DIR #{__path} NOT CREATED"
        else
          console.log " > DIR #{__path} CREATED"
        fn()  


  _rename:(_path, _new, fn, __path = @tmp(_path), __new = @tmp(_new)) ->
    fs.rename __path, __new, (err, data) => 
      if err?
        console.log " > #{__path} NOT RENAMED TO #{__new}", 
      else
        console.log " > #{__path} RENAMED TO #{__new}"
      fn()

  _change: (_path, fn, __path = @tmp(_path)) -> 
    try
      stat = fs.statSync __path
    catch e
      throw Error " > FILE #{__path} DOESN`T EXISTS (CHANGE)" 
    
    unless stat.isDirectory()
      fs.writeFile __path, "#{fs.readFileSync(__path, 'utf8')}#{new Date().toString()}\n", (err, data) =>
        if err?
          console.log " > FILE #{__path} NOT CHANGED"
        else
          console.log " > FILE #{__path} CHANGED"
        fn()
    
    else
      for _file in fs.readDirSync __path
        file = path.join(__path, _file)
        unless fs.statSync(file).isDirectory()
          __change(file);
          break;

global.TestEngine = TestEngine
  





