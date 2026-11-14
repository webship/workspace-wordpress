Feature: An editor writes a page and removes it again
  As an editor
  I want to write, publish and delete a page
  So that the suite proves the editor works and leaves the site as it found it

  Scenario: The editor publishes a page, sees it on the site and deletes it
    Given I am a logged in user with the "editor" user
    And I am on the new page screen
    When I set the page title to "A page written by a scenario"
    And I write "This page is written and removed by the suite." in the page content
    And I publish the page
    Then the page should be published in the editor
    When I view the page
    Then the response status code should be 200
    And I should see "A page written by a scenario"
    And I should see "This page is written and removed by the suite."
    When I move the page "A page written by a scenario" to the trash from the list
    Then the page "A page written by a scenario" should be in the trash
    When I delete the page "A page written by a scenario" permanently
    Then the pages list should not include "A page written by a scenario"
