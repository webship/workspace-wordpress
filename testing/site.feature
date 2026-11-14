Feature: The site answers and its accounts work
  As the owner of the site
  I want the front page, the login screen and each default account to work
  So that a build that came out broken is caught before anything else is tested

  # Placed by the workspace's testing setup as a starting point: it is yours to change.
  # The accounts are the default ones (cmd-tools-add-users.sh); a scenario logs in by a handle of
  # the users registry in cucumber.js, so no password is written here.

  @critical
  Scenario: The front page is served
    Given I am an anonymous user
    And I am on the homepage
    Then the response status code should be 200
    And I should see the site title

  @critical
  Scenario: The login screen is served with its form
    Given I am on the login page
    Then the response status code should be 200
    And I should see the login form

  Scenario Outline: Each default account logs in and has its role
    Given I am a logged in user with the "<handle>" user
    Then I should be logged in as the "<handle>" user
    And my account should have the "<role>" role

    Examples:
      | handle      | role          |
      | admin       | administrator |
      | editor      | editor        |
      | author      | author        |
      | contributor | contributor   |
      | subscriber  | subscriber    |

  Scenario: An account is refused a screen its role may not open
    Given I am a logged in user with the "editor" user
    When I go to the "Plugins" admin screen
    Then I should see the access denied screen

  Scenario: An anonymous visitor has no session
    Given I am an anonymous user
    And I am on the homepage
    Then I should not see the admin bar
    And I should not be logged in
