/**
 * WordPress for Webship Workspace: a platform plugin.
 *
 * What the package carries is placed by the installer from the manifest: the builder and the
 * WP-CLI tool in the sites folders, their functions and argparse under core/scripts/plugins/wordpress/,
 * the agents in the AI Agents folder. The dashboard needs nothing drawn for it: the builder is in the
 * Build list because it is a cmd-*-project.sh, the row menus are the core's, the agents are listed
 * like any other. What register() adds is what the assistant is told.
 *
 * Everything the dashboard is asked for goes through `api`; this package requires nothing from the
 * dashboard's own files, so it can be installed from npm and removed without a trace.
 */

import type { PluginApi } from '@webship.co/workspace-plugin-api';

/** The plugin's name, which is also the DDEV project type its functions are named after. */
export const PLATFORM = 'wordpress';

/** The commands the installer places in every sites folder. */
export const COMMANDS = ['cmd-wordpress-project.sh', 'cmd-tools-wordpress-cli.sh'];

/** The agents the installer places in the AI Agents folder. */
export const AGENTS = ['wordpress-site-builder', 'wordpress-tester'];

/** What the assistant is told about WordPress in this workspace. */
export function assistantContext(): string {
  return [
    'WordPress (a plugin, @webship.co/workspace-wordpress): a WordPress site is built with',
    '`bash cmd-wordpress-project.sh <name> --install --add-users` from a sites folder (dev, test, sandboxes, demos),',
    'in a container like every other project, at https://<name>.ddev.site.',
    '`bash cmd-tools-wordpress-cli.sh <name>` says what the site is; `--run "<wp-cli command>"` runs WP-CLI in it,',
    '`--update` updates the core, the plugins and the themes, `--add-users` adds the default accounts (one per role).',
    '`bash cmd-tools-testing.sh <name>` sets up webship-js with the WordPress step pack; `--run` runs the suite.',
    `For WordPress work, hand over to the agents ${AGENTS.map((a) => `\`${a}\``).join(' and ')}.`,
    'Never run wp, composer, npm or mysql on the host for a project; never write database settings into wp-config.php.',
  ].join(' ');
}

export function register(api: PluginApi): void {
  api.addAssistantContext(assistantContext);
}
