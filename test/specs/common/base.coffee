context 'events handling', ->

  describe 'of simple.file creation', ->

    beforeEach ->
      console.log "BEFORE EACH of simple.file creation"
      @engine.create 'simple.file', =>
        @args = => _.first @engine.$create.args
        console.log "ON simple.file CREATION ARGS = ", @args()

    it 'should invoke create callback once', (done) ->

      @engine.test => 
        @engine.$create.calledOnce.should.be.true
        done()
        
    it 'should pass an instance of File class to this callback', (done) -> 
      
      @engine.test => 
        @args().should.have.length(1) and _.first(@args()).should.be.an.instanceof File
        _.first(@args()).stat.isDirectory().should.be.false
        done()

    it "should pass object with corresponding name, path and stat properties", (done) ->

      @engine.test => 
        file = _.first(@args())
        file.should.have.property 'name', 'simple.file'
        file.should.have.property 'path', (path.join TEMP_DIR, 'simple.file')
        done()

# - - - - -- - - - -- - - - -- - - - -- - - - -- - - - -- - - - - OK



  describe 'of simple_directory creation', ->

    beforeEach ->
      console.log "BEFORE EACH of simple_directory creation"
      @engine.create 'simple_directory', (err, data) =>
        @args = => _.first @engine.$create.args
        console.log "ON simple_directory CREATION ARGS = ", @args()

    it 'should invoke create callback once', (done) ->

      @engine.on 'create', (file) => 
        console.log " $$$$$$$$$$$$$$$$$$ ", file.name, @args()

      @engine.test => 
        @engine.$create.calledOnce.should.be.true
        done()
        
    it 'should pass an instance of Dir class to this callback', (done) -> 
      
      @engine.test => 
        @args().should.have.length(1) and _.first(@args()).should.be.an.instanceof Dir
        _.first(@args()).stat.isDirectory().should.be.true
        done()

    it "should pass object with corresponding name, path and stat properties", (done) ->

      @engine.test => 
        file = _.first(@args())
        file.should.have.property 'name', 'simple_directory'
        file.should.have.property 'path', (path.join TEMP_DIR, 'simple_directory')
        done()



  # describe "Rename event", ->
    
  #   it 'should detect file renaming', (done) ->
  #     @engine.create('test.file').then().rename('test.file', 'new.file').test =>
  #       @engine.$create.calledOnce.should.be.true
  #       done()

  # describe "Remove event", ->

  #   it 'should detect file removing', (done) -> 
  #     @engine.create('test.file').then().remove('test.file').test =>
  #       @engine.$create.calledOnce.should.be.true
  #       done()




    