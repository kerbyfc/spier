describe 'Spier class', ->

  beforeEach ->
    @Spier = require '../../../spier.coffee'
    @Spier.prototype[name] = sinon.spy(fn) for name, fn of @Spier.prototype when _.isFunction fn
    @spier = new @Spier()

  after: ->
    @spier.stop()
    delete @Spier
    delete @spier

  describe '::spy', ->

    it 'should return an instance of Spier class', ->
      spier = @Spier.spy()
      spier.should.be.an.instanceof @Spier
      spier.stop()

  describe '::stat', ->
    
    it 'should return fs.Stats object', ->
      stat = @Spier.stat __dirname, 'spier.coffee'
      stat.should.be.an.instanceof fs.Stats

  describe '@constructor()', ->
    
    beforeEach -> @spier.spy().stop()

    it 'should invoke #configure method', ->
      @spier.configure.calledOnce.should.be.true

  describe '@configure( options = {} )', ->

    it 'should invoke #setup number of times equal to total length of defaults and flags properties', ->
      @spier.setup.callCount.should.equal _.size( _.extend @spier.defaults, @spier.flags )

    context 'when options have property noops:true', -> 

      it 'should have default handlers for all events', -> 
        @test = new @Spier noops:true
        @test.options.should.have.property 'noops', true
        (_.size @test.handlers).should.equal 4

  describe '@setup()', ->

    beforeEach -> @spier.spy().stop()

    it 'should specify @options of Spier instance and create a regexp for target and ignore properties', ->
      @spier.setup 'ignore', '*.js'
      @spier.options.should.have.property 'ignore'
      @spier.options.ignore.should.be.an.instanceof RegExp

  describe '@spy()', ->

    it 'should set target option', ->
      @spier.options.should.have.property 'target', null
      @spier.spy().stop()
      @spier.options.target.should.be.an.instanceof RegExp


  describe '@start()', -> 

    it 'should set @scope to an instance of sDir class, and also set @pause to false', -> 
      @spier.spy()
      @spier.should.have.property 'scope'
      @spier.scope.should.be.an.instanceof sDir
      @spier.pause.should.be.false

    it 'should invoke @lookout after @delay milliseconds', (done) ->
      @spier.spy()
      setTimeout( => 
        @spier.stop()
        @spier.lookout.called.should.be.ok
        done()
      , 50)

  describe '@stop()', -> 

    it 'should set @pause to true, clear @timeout and set it to null', ->
      @spier.spy()
      @spier.pause.should.not.be.ok
      @spier.stop()
      @spier.pause.should.be.ok
      @spier.should.have.property 'timeout', null


  describe '@lookout()', ->

    it 'should set @timeout and invoke itself recursively until @stop()', (done) ->
      @spier.spy()
      setTimeout => 
        @spier.lookout.callCount.should.be.above 4
        @spier.stop()
        setTimeout =>
          @spier.lookout.callCount.should.be.above 4
          done()
        , 60
      , 200

  describe '@on()', ->

    it 'should add event handler to @handlers', (done) ->
      @spier.on 'create', => 
        done()
      @spier.handlers.create()

  describe '@off()', -> 

    it 'should delete event handler from @handlers', -> 
      @spier.on 'create', => false
      @spier.handlers.create.should.be.ok
      @spier.off 'create'
      @spier.handlers.should.not.have.property 'create'


      
