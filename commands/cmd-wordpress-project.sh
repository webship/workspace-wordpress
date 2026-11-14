#!/usr/bin/env bash

# workspace-name: WordPress (latest)

# Installed by the WordPress plugin (plugins.sh --install wordpress); __WORKSPACE__ is the workspace it was installed into.
#
# Build a WordPress site in a container: the latest release, or the one --version names, at
# https://<name>.ddev.site. With --install the site is installed with the workspace account as its
# administrator; with --add-users it also gets the default accounts, one per role.

# Bootstrap.
# Find the workspace tooling from this script, so a fresh clone needs no setup.
WORKSPACE_SCRIPTS="${WORKSPACE_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../core/scripts" && pwd)}";
source ${WORKSPACE_SCRIPTS}/bootstrap.sh || exit 1 ;

# Load workspace settings.
eval $(parse_yaml ${WORKSPACE_CONFIG}/workspace.__WORKSPACE__.settings.yml);

# Set site version.
site_version="latest";

# Distribution.
distribution_name="wordpress";
distribution_title="WordPress";
distribution_webroot="";

ARGPARSE_DESCRIPTION="Build a ${distribution_title} project in __WORKSPACE__"
# The args file comes with the plugin: core/scripts/plugins/wordpress/ is where plugins.sh --install puts it.
source ${WORKSPACE_SCRIPTS}/plugins/wordpress/args/arg-wordpress.sh || exit 1 ;

shift $#;

wordpress_build ;
