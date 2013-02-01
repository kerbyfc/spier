describe "Spier", ->

  before ->
    fs.mkdirSync TEMP_DIR

  after ->
    wrench.rmdirSyncRecursive path.join __tmpDir

  describe "Programmatic interface", ->
    require spec for spec in glob.sync( path.join SPEC_DIR, 'programmatic/*.coffee')

  describe "CLI interface", ->
    require spec for spec in glob.sync( path.join SPEC_DIR, 'cli/*.coffee')

  describe "Events handling", ->
    require spec for spec in glob.sync( path.join SPEC_DIR, 'events/*.coffee')