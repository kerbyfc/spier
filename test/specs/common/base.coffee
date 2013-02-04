describe 'Create event handling', ->

  beforeEach (done) ->
    @spier = __init()
    done()

  it 'should detect file creation', (done) ->

    cb = (file) =>
      test.calledOnce.should.equal true, 'Blah, Blah'
      test.called.should.equal true
      done()

    test = sinon.spy cb

#    setTimeout =>
#      test()
#    , 20
#
#

    @spier.on 'create', test
    @spier.spy()

    setInterval =>
      test()
      __create 'test.file'
    , 100