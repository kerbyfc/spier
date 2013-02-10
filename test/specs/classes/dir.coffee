describe 'sDir class', ->

  beforeEach -> 
    sDir.prototype[name] = sinon.spy(fn) for name, fn of sDir.prototype when _.isFunction fn

  describe '@constructor()', -> 

    it 'should invoke @setup once', -> 
      dir = new sDir
      dir.setup.calledOnce.should.be.true

  describe '@setup', -> 

    it 'should extend @defaults with argument object to @', -> 
      defaults = sDir.prototype.defaults
      dir = new sDir
      typeof(dir.files.should.be.an.instanceof 'Object'
