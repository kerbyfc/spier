describe 'Create event handling', ->

  beforeEach (done) ->
    @spier = new Spier {root: TEMP_DIR}
    done()

  afterEach ->
#    __cleanup()

  it 'should detect file creation', ->
    @spier.spy()
    __create 'test.file'
    true