---
name: wordpress-scenarios
description: Write and run webship-js scenarios for a WordPress site of the Webship Workspace with the WordPress step pack (`@webship-js/wordpress-steps`) — the phrases of the pack by area (sessions and roles, admin screens, the block editor, comments, the theme, the REST API and feeds), the handles of the users registry, and the workspace command that runs them in the site's container. Use when asked to "write a scenario for this WordPress site", "test the editor role", "which step is there for the admin menu", "add a feature for publishing a page", or when a `.feature` file of a WordPress project is being written or fixed.
argument-hint: '<site> [what to cover]'
---

# wordpress-scenarios

Scenarios for a WordPress site of a Webship Workspace (`~/workspace`, container-based, DDEV by
default), written from the steps of [`@webship-js/wordpress-steps`](https://github.com/webship/wordpress-steps)
and of [webship-js](https://github.com/webship/webship-js) itself, and run in the site's container
by the workspace's own command. It comes with the WordPress plugin
(`@webship.co/workspace-wordpress`), like the builder (`cmd-wordpress-project.sh`), the WP-CLI tool
(`cmd-tools-wordpress-cli.sh`) and the agents `wordpress-site-builder` and `wordpress-tester`.

## Where everything is

| What | Where |
| --- | --- |
| The site | `~/workspace/<folder>/<site>`, at `https://<site>.ddev.site` (`<folder>` is a sites folder: `dev`, `test`, `sandboxes`, `demos`) |
| The suite's configuration | `<site>/cucumber.js`: the step definitions it loads and the users registry (`worldParameters.users`) |
| The features | `<site>/tests/features/*.feature` (`site.feature` is the first one the setup wrote) |
| The pack's steps | `<site>/node_modules/@webship-js/wordpress-steps/tests/step-definitions/*.steps.js` |
| webship-js's steps | `<site>/node_modules/webship-js/tests/step-definitions/*.js` |
| The reports | `<site>/tests/reports/` |

## The order of work

1. **Make sure the testing stack is there.** From the sites folder:
   ```bash
   cd ~/workspace/<folder>
   bash cmd-tools-testing.sh <site>
   ```
   It adds webship-js, the step pack, the users registry and `tests/features/site.feature`, and
   makes sure the default accounts are on the site. It is safe to run again: it adds what is
   missing and keeps what was changed.
2. **Read the installed steps before writing a phrase.** They are the source of truth: the pack
   moves, and a phrase from memory is a guess.
   ```bash
   cd ~/workspace/<folder>/<site>
   grep -hE "^(Given|When|Then)\(" node_modules/@webship-js/wordpress-steps/tests/step-definitions/*.steps.js
   ```
   Every step carries a comment block with five examples above it; open the file when a phrase
   is not obvious.
3. **Look at the page first** (the Playwright MCP browser, a tab of your own) when the scenario
   is about a screen you have not seen. A scenario written without having seen the page asserts
   what you imagine.
4. **Write the feature** in `<site>/tests/features/`, from phrases that exist (the tables below).
5. **Match every step without a browser**, then run the feature, then the suite:
   ```bash
   cd ~/workspace/<folder>
   bash cmd-tools-testing.sh <site> --dry-run --path tests/features/<name>.feature
   bash cmd-tools-testing.sh <site> --run --path tests/features/<name>.feature
   bash cmd-tools-testing.sh <site> --run --tags "@critical"
   bash cmd-tools-testing.sh <site> --run
   ```
   A dry run says `Undefined` for a phrase no definition matches: fix the phrase, do not write a
   step for it.

## Accounts: a handle, never a password

A scenario logs in by a handle of the users registry. The default accounts are on the site
already (`bash cmd-tools-wordpress-cli.sh <site> --add-users` adds them again if they were removed):

| Handle | Account | Role |
| --- | --- | --- |
| `admin` | `administrator` | administrator |
| `editor` | `editor` | editor |
| `author` | `author` | author |
| `contributor` | `contributor` | contributor |
| `subscriber` | `subscriber` | subscriber |

```gherkin
Given I am a logged in user with the "editor" user
Then I should be logged in as the "editor" user
And my account should have the "editor" role
```

## The phrases, by area

Each line is a phrase the pack defines, and each one passed on a site built with
`bash cmd-wordpress-project.sh <site> --install --add-users` (the names in quotes are that site's:
its theme, its sample content). Most `should` steps also take the negative: `should not see`,
`should not be`, `should not list`.

### Sessions and roles

```gherkin
Given I am an anonymous user
Given I am not logged in
Given I am on the login page
Given I am a logged in user with the "editor" user
When I log out
Then I should see the login form
Then I should be logged in as the "editor" user
Then I should not be logged in
Then my account should have the "editor" role
Then the admin bar should show the account "editor"
Then I should see the admin bar
```

### Admin screens, by the name on the menu

```gherkin
When I go to the "Pages" admin screen
Then I should be on the "Pages" admin screen
Then I should see the access denied screen
Then I should see the "At a Glance" dashboard widget
Then the admin menu should list "Pages"
Then the admin menu should not list "Plugins"
Then the "Settings" admin submenu should list "Permalinks"
When I click "Library" under "Media" in the admin menu
Then the "Akismet Anti-spam: Spam Protection" plugin should be installed
Then the "Twenty Twenty-Five" theme should be active
Then the active theme should be a block theme
Then the permalink structure should be "Day and name"
When I go to the "General Settings" admin screen
Then the "Site Title" setting should be "dev mysite"
```

The dashboard widget step needs the Dashboard open, and a setting step needs its settings screen
open. The plugin, theme and permalink steps open their own screen.

### Content in the block editor

```gherkin
Given I am on the new page screen
When I open the page "Sample Page" in the editor
When I set the page title to "About us"
When I write "About this site." in the page content
When I save the page as a draft
When I publish the page
When I update the page
When I view the page
When I move the page to the trash
Then the page should be published in the editor
Then the editor should offer "Publish"
Then the pages list should include "About us"
Then the page "About us" should be published
When I move the page "About us" to the trash from the list
Then the page "About us" should be in the trash
When I delete the page "About us" permanently
```

`post` and `page` are interchangeable in every one of these. A contributor has no Publish button:

```gherkin
Then the editor should offer "Submit for Review"
When I submit the post for review
Then the post should be pending review in the editor
```

Categories and tags are for posts:

```gherkin
When I add the category "News"
When I file the post under the category "News"
Then the post should be in the category "News"
When I delete the category "News"
Then the category "News" should not exist
```

### The public site, the theme, search and comments

```gherkin
Given I am on the homepage
Given I am on a post
Given I am on a page
Then I should see the site title
Then I should see the page title
Then I should see post entries
Then the navigation menu should list "Sample Page"
Then I should see the header template part
When I search for "Hello"
Then the search results should include "Hello world!"
Then I should see the comment form
When I submit the comment "A comment from a scenario"
Then the comment "A comment from a scenario" should be approved
When I trash the comment "A comment from a scenario"
Then the comment "A comment from a scenario" should be in the trash
When I delete the comment "A comment from a scenario" permanently
```

### The machine-readable site

```gherkin
Then the REST API should be available
Then the REST route "/wp/v2/posts" should list at least 1 item
Then the REST route "/wp/v2/settings" should require authentication
Then the site feed should be a valid RSS feed with at least 1 item
Then the XML sitemap should be served
```

`I am an anonymous user`, `I am on the homepage`, `I should see "<text>"` and
`the response status code should be 200` are webship-js's own steps; its status codes, classes,
landmarks and accessibility audits are used as they are and never redefined for this platform.

## Traps found on a real site

- `I should see the page title` compares with the title that `Given I am on a page` (or
  `on a post`) captured. After `When I view the page` nothing was captured: assert the text with
  `Then I should see "<the title>"`.
- A site title is `<folder> <site>` after a build (`dev mysite`), until somebody changes it.
- The permalink structure is named as the Permalinks screen names it (`Day and name`,
  `Post name`), not by its pattern.
- `Then robots.txt should be served` is a phrase of the pack, and it fails on a site as the builder
  leaves it: the container's web server answers `/robots.txt` itself, with a 404 while the site has
  no such file. Leave it out of a suite until the site has one.
- A post in the trash is still there: `When I delete the post "<title>" permanently` after the
  trash step, or the next run finds it.

## Rules

- **No account is created in a suite.** No `wp user create` in a hook, no registration scenario
  that leaves an account behind. A role the registry does not have is asked for, not made.
- **Never the workspace account.** The site's own administrator is not in the registry; `admin`
  is the `administrator` default account.
- **No password in a feature file**, except where a wrong password is the subject.
- **No platform name in a step phrase**: `I am on the login page`, never a phrase that names the
  platform. The same holds for a custom step.
- **No selector and no address when a step says it**: `the "Plugins" admin screen`, not the path
  of the screen.
- **What a scenario creates, it removes** in the same scenario, under a title nobody else uses.
- **A custom step is the last resort**: look in the pack and in webship-js first, write it in
  `<site>/tests/step-definitions/` with a comment block and examples, and say it may belong in
  the pack.
- **Everything runs in the container**, through `cmd-tools-testing.sh`. Never `npx cucumber-js`
  or `npx playwright` on the host.
- **A failing scenario is a result.** No `@wip`, no longer timeout, no looser assertion to turn a
  run green: say what the site did.

## Examples that run

`examples/` holds three features that pass on a site built with
`bash cmd-wordpress-project.sh <site> --install --add-users`. Copy one into the suite and run it:

```bash
cp ~/workspace/ai-skills/wordpress-scenarios/examples/roles-and-screens.feature ~/workspace/<folder>/<site>/tests/features/
cd ~/workspace/<folder>
bash cmd-tools-testing.sh <site> --run --path tests/features/roles-and-screens.feature
```

| Feature | What it shows |
| --- | --- |
| `examples/roles-and-screens.feature` | Each role reaching, or being refused, an admin screen; the admin menu of a role |
| `examples/page-lifecycle.feature` | An editor writing, publishing, viewing and deleting a page: content a scenario creates and removes |
| `examples/machine-readable.feature` | The REST API, the feed and the sitemap, with no browser session |
