Feature: Each role reaches the screens it may use
  As the owner of the site
  I want every role to open its own screens and to be refused the others
  So that a change of capabilities is caught by the suite

  # The accounts are the default ones; a scenario logs in by a handle of the users registry.

  Scenario: An editor opens the Pages screen and has no Plugins menu
    Given I am a logged in user with the "editor" user
    When I go to the "Pages" admin screen
    Then I should be on the "Pages" admin screen
    And the admin menu should list "Pages"
    And the admin menu should not list "Plugins"

  Scenario: An editor is refused the Plugins screen
    Given I am a logged in user with the "editor" user
    When I go to the "Plugins" admin screen
    Then I should see the access denied screen

  Scenario: A subscriber is refused the Posts screen
    Given I am a logged in user with the "subscriber" user
    When I go to the "Posts" admin screen
    Then I should see the access denied screen

  Scenario: An administrator sees the theme the site runs on
    Given I am a logged in user with the "admin" user
    When I go to the "Themes" admin screen
    Then I should be on the "Themes" admin screen
    And the active theme should be a block theme
