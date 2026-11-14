#!/usr/bin/env bash

# Installed by the WordPress plugin (plugins.sh --install wordpress); __WORKSPACE__ is the workspace it was installed into.
#
# WP-CLI for one WordPress project of this workspace, in its container: say what the site is,
# run a WP-CLI command, update the core, the plugins and the themes, add or remove the default
# accounts. Nothing here runs on the host.

# Bootstrap.
# Find the workspace tooling from this script, so a fresh clone needs no setup.
WORKSPACE_SCRIPTS="${WORKSPACE_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../core/scripts" && pwd)}";
source ${WORKSPACE_SCRIPTS}/bootstrap.sh || exit 1 ;

# Load workspace settings.
eval $(parse_yaml ${WORKSPACE_CONFIG}/workspace.__WORKSPACE__.settings.yml);

# Distribution.
distribution_name="wordpress";

ARGPARSE_DESCRIPTION="Run WP-CLI on a WordPress project of __WORKSPACE__: status, a command, updates, the default accounts"
# The args file comes with the plugin: core/scripts/plugins/wordpress/ is where plugins.sh --install puts it.
source ${WORKSPACE_SCRIPTS}/plugins/wordpress/args/arg-wordpress-cli.sh || exit 1 ;

shift $#;

wordpress_cli_tool ;
