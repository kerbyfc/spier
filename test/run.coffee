describe "Spier", ->

  beforeEach (done) ->
    __cleanup =>
      console.log "CLEANUP DONE, NEW ENGINE"
      @timeout 3000
      console.log "TIMEOUT 3000"
      done()

  afterEach -> 
    console.log "@engine.destroy()"
    @engine.destroy()
    delete @engine

  after (done) -> 
    __cleanup => 
      console.log "AFTER ALL CLEANUP"
      done()

  for type in ['common', 'cli']
    if specs = glob.sync path.join SPEC_DIR, type, '*.coffee'
      require spec for spec in specs