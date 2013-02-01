describe "Spier", ->

  before ->
    __cleanup()
    try fs.mkdirSync TEMP_DIR

  for type in ['common', 'cli']
    if specs = glob.sync path.join SPEC_DIR, type, '*.coffee'
      require spec for spec in specs