/**
 * WordPress for Webship Workspace: a platform plugin.
 *
 * What the package carries is placed by the installer from the manifest: the builder and the
 * WP-CLI tool in the sites folders, their functions and argparse under core/scripts/plugins/wordpress/,
 * and its AI items (ai/ in this package) in the folder of their kind: the agents in AI Agents, the skill
 * in AI Skills, the command in AI Commands, the prompts in AI Prompts. The dashboard needs nothing drawn
 * for it: the builder is in the Build list because it is a cmd-*-project.sh, the row menus are the
 * core's, the AI items are listed like any other. What register() adds is what the assistant is told.
 *
 * Everything the dashboard is asked for goes through `api`; this package requires nothing from the
 * dashboard's own files, so it can be installed from npm and removed without a trace.
 */

import type { PluginApi } from '@webship.co/workspace-plugin-api';

/** The plugin's name, which is also the project type (DDEV's, and the one kept in compose.yaml on another runtime) its functions are named after. */
export const PLATFORM = 'wordpress';

/** The commands the installer places in every sites folder. */
export const COMMANDS = ['cmd-wordpress-project.sh', 'cmd-tools-wordpress-cli.sh'];

/** The agents the installer places in the AI Agents folder. */
export const AGENTS = ['wordpress-site-builder', 'wordpress-tester'];

/** The skill the installer places in the AI Skills folder (a folder each, with its SKILL.md). */
export const SKILLS = ['wordpress-scenarios'];

/** The slash command the installer places in the AI Commands folder. */
export const AI_COMMANDS = ['wordpress-test'];

/** The prompts the installer places in the AI Prompts folder: each a whole launch command for a new session. */
export const PROMPTS = ['wordpress-build-and-test', 'wordpress-scenarios-for-a-role'];

/** What the assistant is told about WordPress in this workspace. */
export function assistantContext(): string {
  return [
    'WordPress (a plugin, @webship.co/workspace-wordpress): a WordPress site is built with',
    '`bash cmd-wordpress-project.sh <name> --install --add-users` from a sites folder (dev, test, sandboxes, demos),',
    'in a container like every other project: on DDEV by default, at https://<name>.ddev.site, or with `--runtime docker` or',
    '`--runtime kubernetes` on Docker Compose or a Kubernetes cluster, at the address the build prints.',
    '`bash cmd-tools-wordpress-cli.sh <name>` says what the site is; `--run "<wp-cli command>"` runs WP-CLI in it,',
    '`--update` updates the core, the plugins and the themes, `--add-users` adds the default accounts (one per role).',
    '`bash cmd-tools-testing.sh <name>` sets up webship-js with the WordPress step pack; `--run` runs the suite.',
    `For WordPress work, hand over to the agents ${AGENTS.map((a) => `\`${a}\``).join(' and ')}.`,
    `The plugin also places the skill ${SKILLS.map((a) => `\`${a}\``).join(', ')} (the step pack's phrases, by area) in ai-skills/,`,
    `the command ${AI_COMMANDS.map((a) => `\`/${a} <site>\``).join(', ')} in ai-commands/ and the prompts ${PROMPTS.map((a) => `\`${a}\``).join(' and ')} in ai-prompts/.`,
    'The same commands work on every runtime. Never run wp, composer, npm or mysql on the host for a project; never write',
    'database settings into wp-config.php on DDEV (on another runtime the builder writes the ones of the project\'s own stack).',
  ].join(' ');
}

export function register(api: PluginApi): void {
  api.addAssistantContext(assistantContext);
}
