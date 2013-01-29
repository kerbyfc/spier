describe "Spier", ->

  describe "Programmatic interface", ->
    require spec for spec in glob.sync( path.join SPEC_DIR, 'programmatic/*.coffee')

  describe "CLI interface", ->
    require spec for spec in glob.sync( path.join SPEC_DIR, 'cli/*.coffee')

  describe "Events handling", ->
    require spec for spec in glob.sync( path.join SPEC_DIR, 'events/*.coffee')