# A platform plugin, from this one

`@webship.co/workspace-wordpress` is the pattern for the plugin of any other platform (Joomla, TYPO3,
django CMS, Odoo, Ghost, Backdrop CMS, Craft CMS, PrestaShop, Magento, Gatsby, Astro). A platform
plugin draws nothing on the dashboard: it places commands, functions and agents, and the core does
the rest. Below, `<p>` is the platform's name.

## Copy, then rename

1. Copy the repository into `workspace-<p>`. Replace `wordpress` with `<p>`, `WordPress` with the
   platform's written name and `WP` (the prefix of the account variables) with its own, in file
   names and in content.
2. `<p>` is three things at once, so choose it once: the plugin's name in the manifest, the folder
   `core/scripts/plugins/<p>/`, and the **DDEV project type** when DDEV has one (`typo3`, `craftcms`,
   `magento2`, `backdrop`). The row's Users menu reads the project type and asks for the user list of
   that name. A platform without a project type of its own (`php`, `generic`) is recognised by a file
   instead: change `<p>_is_project`, and its accounts are added with `cmd-tools-<p>-cli.sh --add-users`.
3. Keep these names exactly; the core's tools call them:

| Function in `scripts/functions/fun-<p>.sh` | Called by |
| --- | --- |
| `set_<p>_users` | `cmd-tools-add-users.sh <project> <p>`, the Users menu |
| `add_<p>_users`, `cancel_<p>_users` | the same tools |
| `testing_configure_<p>` | `cmd-tools-testing.sh <project>`; returns 0 and changes nothing for a project that is not its own |

4. Keep the shape of each command: the `# workspace-name:` header on the builder, the bootstrap
   line that finds the tooling from the script's own path, `workspace.__WORKSPACE__.settings.yml`,
   the args sourced from `${WORKSPACE_SCRIPTS}/plugins/<p>/args/`, and one function call as the last
   line. `--help` must do nothing but print.
5. Keep the manifest's keys: `commands` (types `sites`), `scripts.functions`, `scripts.args`,
   `scripts.machine` (the first feature), `ai.agents`, `features`.

## What differs per platform

| | WordPress here | Decide for `<p>` |
| --- | --- | --- |
| Project type | `ddev config --project-type=wordpress`, docroot at the project root | The DDEV type and docroot; a service of its own (a database other than the default, a search engine) goes in the builder, after `ddev config` |
| Getting the code | `ddev wp core download --version=<x>` | Composer `create-project`, a tarball, `npm create`, a container image |
| The CLI | WP-CLI (`ddev wp`) | The platform's console, always through the container; the tool is `cmd-tools-<p>-cli.sh` with `--run`, `--update`, `--add-users`, `--cancel-users` |
| Install | `wp core install` with the workspace account | The platform's installer, non-interactive; the administrator is always the workspace account (`account_name`, `account_pass`, `account_mail`) |
| Database settings | Written by the container tool; the plugin writes none | The same rule where the tool writes them; otherwise the builder writes the container's own values (`db`/`db`/`db`) and nothing personal |
| Default accounts | One per role: `administrator`, `editor`, `author`, `contributor`, `subscriber`, at `@example.com` | The platform's roles; a platform with no accounts (a static site generator) ships no user functions |
| Test pack | `@webship-js/wordpress-steps` `^2.2.0`, registry prefix `WP` | The platform's step pack and release line, in `<P>_STEPS_PACKAGE` and `<P>_STEPS_VERSION`; the registry and the first feature only if the pack logs in |
| First feature | `testing/site.feature`: front page, login, each account in its role | A handful of scenarios from the pack's own steps, with no platform name in a step phrase |
| Agents | `wordpress-site-builder`, `wordpress-tester` | `<p>-site-builder`, `<p>-tester`, with `model: fable`, the plugin's commands and the same rules: containers only, never the workspace account in a test, never an account created in a suite |

## Before it is pushed

- `npm run lint && npm test`, and `bash -n` on every script.
- In a throwaway workspace: require, activate, install; the builder is in the Build list of `dev`;
  the agents are in the AI Agents folder; build one real site; `cmd-tools-testing.sh <name>` then
  `--run` is green; uninstall leaves nothing.
- The words: the workspace is container-based (DDEV by default). Addresses are `@example.com`, paths
  are `/home/YOUR_USER`, passwords that are a person's are `CHANGE_ME`.
