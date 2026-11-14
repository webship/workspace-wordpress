# @webship.co/workspace-wordpress

WordPress for the [Webship Workspace](https://github.com/webship/workspace) dashboard: a builder
that makes a real WordPress site in a container, a WP-CLI tool for the sites it built, the default
accounts, the [WordPress step pack](https://github.com/webship/wordpress-steps) wired into the
workspace's testing setup, and two AI agents that know all of it.

The workspace is container-based (DDEV by default): a WordPress project is a row like any other, so
the row menus the core draws (start, stop, launch, backup, clone, remove, tests) work on it unchanged.

This is the reference platform plugin: the plugins for the other platforms are made from it, see
[docs/cms-plugin-pattern.md](docs/cms-plugin-pattern.md).

## Use it

```bash
cd ~/workspace
bash core/scripts/plugins.sh --require github:webship/workspace-wordpress   # npm install into the dashboard
bash core/scripts/plugins.sh --activate wordpress                            # plugins.wordpress in settings.yml
bash core/scripts/plugins.sh --install wordpress                             # commands, functions, args, agents
bash core/scripts/plugins.sh --configure wordpress                           # nothing to configure: it has no settings file
```

The same four steps are buttons on the dashboard's **Settings → Plugins** page. `--install` is
idempotent. `--uninstall` removes what it placed; an agent you edited stays, and a folder's own
example builder of the same name comes back.

The commands land in the sites folders that are in the workspace (`dev`, `test`, `sandboxes`,
`demos`); the agents land in the AI Agents folder (`ai-agents/`) when the workspace has one, and are
installed into `~/.claude/agents` from there like any other agent.

The agents, the builder's flags in the Build form, the Users menu and the step pack in the testing
setup need a Webship Workspace after 1.0.6; an older one still places the commands, and they build
and manage sites from the command line.

## What the package holds

| Path | What it is |
| --- | --- |
| `commands/cmd-wordpress-project.sh` | The builder, in the Build list as **WordPress (latest)**, installed into every sites folder |
| `commands/cmd-tools-wordpress-cli.sh` | WP-CLI for one project: what the site is, a command, updates, the default accounts |
| `scripts/functions/fun-wordpress.sh` | The bash functions behind both, sourced by bootstrap once installed; the names the core's tools look for (`set_wordpress_users`, `add_wordpress_users`, `cancel_wordpress_users`, `testing_configure_wordpress`) |
| `scripts/args/arg-wordpress.sh`, `arg-wordpress-cli.sh` | Their argparse; the Build form draws the builder's flags from the first |
| `testing/site.feature` | The first feature a WordPress project gets when testing is set up |
| `agents/wordpress-site-builder.md` | The agent that builds and maintains WordPress sites with these commands |
| `agents/wordpress-tester.md` | The agent that writes and runs scenarios with the WordPress step pack |
| `src/index.ts` | `register(api)`: what the assistant is told about WordPress here |
| `features/wordpress.feature` | Scenarios for the dashboard's own browser suite |
| `docs/cms-plugin-pattern.md` | How to make the plugin for another platform from this one |

The `workspacePlugin` block in `package.json` is the manifest the installer reads.

## The commands

Run them from a sites folder. `--help` is safe on both.

### Build a site

```bash
cd ~/workspace/dev
bash cmd-wordpress-project.sh mysite --install --add-users
```

| Flag | What it does |
| --- | --- |
| `--version <x>` | The release to download: `latest` (the default), `nightly`, or a number such as `6.8.3` |
| `--install` | Install the site, with the workspace account as its administrator |
| `--add-users` | With `--install`: add the default accounts, one per role |
| `--locale <code>` | The language WordPress is downloaded in (`en_US`) |
| `--php-version <x>` | The PHP of the project container |
| `--launch` | Open the site when it is ready |

The site answers at `https://mysite.ddev.site`, the administration at `/wp-admin`. The build runs
`ddev config --project-type=wordpress` with the Node.js of the workspace (24), downloads WordPress
with WP-CLI in the container, and leaves the database settings to the container tool
(`wp-config-ddev.php`): it writes none. A project of the same name is deleted first.

### Work on a site

```bash
bash cmd-tools-wordpress-cli.sh mysite                                    # version, address, plugins, themes, accounts
bash cmd-tools-wordpress-cli.sh mysite --run "plugin install query-monitor --activate"
bash cmd-tools-wordpress-cli.sh mysite --update                           # core, database, plugins, themes, translations
bash cmd-tools-wordpress-cli.sh mysite --plugins                          # plugins only
bash cmd-tools-wordpress-cli.sh mysite --themes                           # themes only
bash cmd-tools-wordpress-cli.sh mysite --add-users                        # the default accounts
bash cmd-tools-wordpress-cli.sh mysite --cancel-users                     # delete them, and what they wrote
```

### The default accounts

| Account | Role | Handle in the tests |
| --- | --- | --- |
| `administrator` | administrator | `admin` |
| `editor` | editor | `editor` |
| `author` | author | `author` |
| `contributor` | contributor | `contributor` |
| `subscriber` | subscriber | `subscriber` |

Each has the address `<account>@example.com` and the password of the workspace's other default
lists. They are for local sites and for tests; the site's own administrator is the workspace
account and is never written into a test. The row's Users menu (**Add the test users**) and
`bash cmd-tools-add-users.sh mysite wordpress` add the same list.

### Test a site

```bash
bash cmd-tools-testing.sh mysite                 # webship-js, the step pack, the users registry, a first feature
bash cmd-tools-testing.sh mysite --run           # run the suite in the container
bash cmd-tools-testing.sh mysite --run --path tests/features/site.feature
```

`cmd-tools-testing.sh` is the workspace's own. For a WordPress project it also adds
`@webship-js/wordpress-steps` to `package.json`, lists its step definitions in `cucumber.js` after
webship-js's own, writes the users registry (the handles above, overridable with
`WP_<HANDLE>_USER` and `WP_<HANDLE>_PASSWORD`), places `tests/features/site.feature` when the
project has none, and makes sure the default accounts are on the site. Run it again and it adds what
is missing and keeps what you changed.

## The agents

| Agent | Use it to |
| --- | --- |
| `wordpress-site-builder` | Build, update, maintain or remove a WordPress site with the commands above, in containers only |
| `wordpress-tester` | Set the testing stack up, look at the site in the Playwright MCP browser first, write scenarios from the pack's steps and run them; it never creates an account in a suite and never writes a platform name into a step phrase |

After `--install` they are in the AI Agents folder of the dashboard; **Install** there puts one into
`~/.claude/agents`, or from the command line:

```bash
cd ~/workspace/ai-agents
bash cmd-tools-ai-items.sh wordpress-tester --install
```

## Develop it

```bash
npm install     # builds dist/ (TypeScript)
npm run lint
npm test        # the manifest, the commands, the agents, the functions against a scaffolded project
```
