describe "Spier", ->

  beforeEach (done) ->
    __cleanup =>
      @engine = new TestEngine()
      console.log 'LOL'
      @timeout 3000
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