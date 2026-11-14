Feature: The site answers to machines as well as to people
  As the owner of the site
  I want the REST API, the feed and the sitemap to be served
  So that readers, search engines and other applications can use the site

  Scenario: The REST API lists the posts and guards the settings
    Then the REST API should be available
    And the REST route "/wp/v2/posts" should list at least 1 item
    And the REST route "/wp/v2/settings" should require authentication

  Scenario: The feed is valid and has entries
    Then the site feed should be a valid RSS feed with at least 1 item

  Scenario: Search engines find the sitemap
    Then the XML sitemap should be served
