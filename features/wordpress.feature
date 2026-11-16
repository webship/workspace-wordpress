Feature: The WordPress plugin on the dashboard
  Once the plugin is activated and installed, the sites folders offer the WordPress builder, each
  AI folder lists the items of its kind the plugin ships, and the Plugins page lists the plugin
  with its steps.

  # The Plugins page names each plugin; the package is on the plugin's own page (the row shows it on hover only).
  Scenario: The plugin is listed on the Plugins page, and its own page names its package
    Given I am on "/settings/plugins"
     Then I should see "WordPress"
     When I go to "/settings/plugin/wordpress"
     Then I should see "@webship.co/workspace-wordpress"

  Scenario: A sites folder offers the WordPress builder
    Given I am on "/dev"
     Then "option[value='cmd-wordpress-project.sh']" should be attached

  # The AI folders are searched by name: with every plugin on, a folder lists more than one page of items.
  Scenario: The AI Agents folder lists the agents the plugin ships
    Given I am on "/ai-agents?q=wordpress-"
     Then I should see "wordpress-site-builder"
      And I should see "wordpress-tester"

  Scenario: The AI Skills folder lists the skill the plugin ships
    Given I am on "/ai-skills?q=wordpress-scenarios"
     Then I should see "wordpress-scenarios"

  Scenario: The AI Commands folder lists the command the plugin ships
    Given I am on "/ai-commands?q=wordpress-test"
     Then I should see "wordpress-test"

  Scenario: The AI Prompts folder lists the prompts the plugin ships
    Given I am on "/ai-prompts?q=wordpress-"
     Then I should see "wordpress-build-and-test"
      And I should see "wordpress-scenarios-for-a-role"
