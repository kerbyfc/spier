describe "Spier", ->

  beforeEach (done) ->
    @timeout 3000
    __cleanup =>
      @engine = new TestEngine()
      console.log 'LOL'
      done()

  afterEach -> 
    @engine.destroy()
    delete @engine

  after (done) -> 
    __cleanup => 
      done()

  for type in ['common', 'cli']
    if specs = glob.sync path.join SPEC_DIR, type, '*.coffee'
      require spec for spec in specs