global.fs = require 'fs'
global.path = require 'path'
global.sinon = require 'sinon'
global.exec = require('child_process').exec
global.shld = require 'should'

global.TEST_ROOT_DIR = __dirname
global.TEMP_DIR = path.join __dirname, 'tmp'

global.__tmp = ->
  path.join TEMP_DIR, path.join(arguments...)

global.__remove = (_path, __path = __tmp(_path)) ->
  stat = fs.statSycn __path
  if stat.isDirectory()
    for _file in fs.readDirSync _path
      __remove path.join(__path, _file)
    fs.rmdirSync __path
  else
    fs.unlinkSync __path

global.__create = (_path, __path = __tmp(_path)) ->
  if __path.substring(__path.lastIndexOf('/') + 2).indexOf('.') > -1
    fs.writeFileSync __path, "#{new Date().toString()}\n"
  else
    fs.mkdirSync __path, '0777'

global.__rename = (_path, _new, __path = __tmp(_path), __new = __tpm(_new)) ->
  fs.renameSync __path, __new

global.__change = (_path, __path = __tmp(_path)) -> 
  try
    stat = fs.statSync __path
  catch e
    throw Error "File #{_path} doesn`t exist." 
  
  unless stat.isDirectory()
    fs.writeFileSync(__path, "#{fs.readFileSync(__path, 'utf8')}#{new Date().toString()}\n")
  
  else
    for _file in fs.readDirSync __path
      file = path.join(__path, _file)
      unless fs.statSync(file).isDirectory()
        __change(file); return




