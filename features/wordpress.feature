Feature: The WordPress plugin on the dashboard
  Once the plugin is activated and installed, the sites folders offer the WordPress builder, the
  AI Agents folder lists the WordPress agents, and the Plugins page lists the plugin with its steps.

  Scenario: The plugin is listed on the Plugins page
    Given I am on "/settings/plugins"
     Then I should see "WordPress"
      And I should see "@webship.co/workspace-wordpress"

  Scenario: A sites folder offers the WordPress builder
    Given I am on "/dev"
     Then "option[value='cmd-wordpress-project.sh']" should be attached

  Scenario: The AI Agents folder lists the agents the plugin ships
    Given I am on "/ai-agents"
     Then I should see "wordpress-site-builder"
      And I should see "wordpress-tester"
