describe "Spier", ->

  describe "Programmatic interface", ->
    require "./specs/programmatic/common"

  describe "CLI interface", ->
    require "./specs/cli/common"
    require "./specs/cli/in"
    require "./specs/cli/ignore"
    require "./specs/cli/pattern"
    require "./specs/cli/dotfiles"
    require "./specs/cli/existing"

  describe "Events handling", ->

    require './specs/events/create'
    require './specs/events/remove'
    require './specs/events/change'
    require './specs/events/rename'