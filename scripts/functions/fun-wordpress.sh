#!/usr/bin/env bash

# WordPress for the Webship Workspace: build a site, run WP-CLI on it, add its default accounts,
# and wire its step pack into the testing setup.
#
# Placed by `plugins.sh --install wordpress` in core/scripts/plugins/wordpress/functions/, where
# bootstrap sources it after the core's own functions. Everything runs in the project's container
# (DDEV by default: `ddev wp …`), never on the host. DDEV writes wp-config-ddev.php for the
# database, so nothing here writes database settings.
#
# Four names are the ones the core's tools look for, under the DDEV project type `wordpress`:
#   set_wordpress_users        the default accounts          (cmd-tools-add-users.sh <project> wordpress)
#   add_wordpress_users        create them with WP-CLI       (the same tool, and --add-users of the builder)
#   cancel_wordpress_users     delete them                   (cmd-tools-cancel-users.sh <project> wordpress)
#   testing_configure_wordpress  the step pack in the testing stack (cmd-tools-testing.sh <project>)

# The step pack a WordPress project is tested with, and the release line it is required at.
readonly WORDPRESS_STEPS_PACKAGE='@webship-js/wordpress-steps';
readonly WORDPRESS_STEPS_VERSION='^2.2.0';

# The default accounts: one per role, the ones a scenario logs in as. Accounts are configuration,
# created once on the site; a test suite never creates or deletes one.
function set_wordpress_users() {
  users=(administrator editor author contributor subscriber);
  local user ;
  for user in "${users[@]}" ; do
    printf -v "user_${user}_name" '%s' "${user}" ;
    printf -v "user_${user}_mail" '%s' "${user}@example.com" ;
    printf -v "user_${user}_password" '%s' 'dD.123123ddd' ;
    printf -v "user_${user}_role" '%s' "${user}" ;
  done
}

# Is this folder a WordPress project? Its DDEV project type says so.
function wordpress_is_project() {
  local project_path="$1";
  grep -qE '^type:[[:space:]]*"?wordpress"?[[:space:]]*$' "${project_path}/.ddev/config.yaml" 2>/dev/null ;
}

# Go to the project a tool was asked about, or say why not.
function wordpress_enter_project() {
  local project_path="${WORKSPACE_ROOT}/${doc_name}/${PROJECT_NAME}";
  if [ ! -d "${project_path}" ] ; then
    echo "No project ${PROJECT_NAME} in ${WORKSPACE_ROOT}/${doc_name}." ;
    return 1 ;
  fi
  if ! wordpress_is_project "${project_path}" ; then
    echo "${doc_name}/${PROJECT_NAME} is not a WordPress project (its .ddev/config.yaml does not say type: wordpress)." ;
    return 1 ;
  fi
  cd "${project_path}" || return 1 ;
}

# Build a WordPress site from nothing: the container, the code, and with --install the site itself.
function wordpress_build() {
  trim_project_name ;
  local base_url="https://${PROJECT_NAME}.ddev.site" ;
  local version="${VERSION:-${site_version:-latest}}" ;
  local php_version="${PHP_VERSION:-${site_php_version:-}}" ;

  cd ${WORKSPACE_ROOT}/${doc_name} || exit 1 ;

  drop_database ;
  rm -rf "${PROJECT_NAME}" ;
  mkdir -p "${PROJECT_NAME}" ;
  cd ${WORKSPACE_ROOT}/${doc_name}/${PROJECT_NAME} || exit 1 ;

  ddev config --project-type=wordpress --docroot="${distribution_webroot}" --project-name=${PROJECT_NAME} \
    --nodejs-version=$(ddev_nodejs_version) ${php_version:+--php-version=${php_version}} --auto || exit 1 ;
  ddev_up start -y || exit 1 ;

  ddev wp core download --version="${version}" --locale="${LOCALE:-en_US}" || { echo "wp core download failed." ; exit 1 ; } ;

  if [ "${INSTALL}" == 'yes' ] ; then
    ddev wp core install --url="${base_url}" --title="${doc_name} ${PROJECT_NAME}" \
      --admin_user="${account_name}" --admin_password="${account_pass}" --admin_email="${account_mail}" \
      --skip-email || { echo "wp core install failed." ; exit 1 ; } ;
    # An install picks a pretty permalink structure but does not always write every rewrite rule
    # (taxonomy archives, for one). A flush writes them again from the structure the install chose.
    ddev wp rewrite flush ;

    if [ "${ADD_USERS}" == 'yes' ] ; then
      set_wordpress_users ;
      add_wordpress_users ;
      cd ${WORKSPACE_ROOT}/${doc_name}/${PROJECT_NAME} || exit 1 ;
    fi

    echo "${doc_name} ${PROJECT_NAME} has been installed: WordPress $(ddev wp core version 2>/dev/null).";
    echo "Go to ${base_url}/wp-admin and log in as ${account_name}";
  else
    [ "${ADD_USERS}" == 'yes' ] && echo "--add-users needs --install: there is no site to add accounts to yet." ;
    echo "${doc_name} ${PROJECT_NAME} is ready to install.";
    echo "Go to ${base_url}";
  fi

  if [ "${LAUNCH}" == 'yes' ] ; then
    ddev launch ;
  fi

  cd ${WORKSPACE_ROOT}/${doc_name};
}

# Create the default accounts with WP-CLI. An account that is already there is left as it is.
# The list is loaded by the caller (set_wordpress_users): the core's add_users, the builder, the CLI tool.
function add_wordpress_users() {
  wordpress_enter_project || return 1 ;
  local user user_name user_mail user_password user_role ;
  for user in "${users[@]}" ; do
    user_name="user_${user}_name"; user_mail="user_${user}_mail";
    user_password="user_${user}_password"; user_role="user_${user}_role";

    echo " ---------------------------------------------------------------- ";
    echo "      User name: ${!user_name}";
    echo "      User mail: ${!user_mail}";
    echo "  User password: ${!user_password}";
    echo "      User role: ${!user_role}";
    echo " ================================================================= ";

    if ddev wp user get "${!user_name}" --field=ID > /dev/null 2>&1 ; then
      echo "   ${!user_name} is already there." ;
    else
      ddev wp user create "${!user_name}" "${!user_mail}" --role="${!user_role}" --user_pass="${!user_password}" ;
    fi
  done
  cd ${WORKSPACE_ROOT}/${doc_name};
}

# Delete the default accounts, and what they wrote.
function cancel_wordpress_users() {
  wordpress_enter_project || return 1 ;
  local user user_name ;
  for user in "${users[@]}" ; do
    user_name="user_${user}_name";
    echo " ---------------------------------------------------------------- ";
    echo "      User name: ${!user_name}";
    echo " ================================================================= ";
    if ddev wp user get "${!user_name}" --field=ID > /dev/null 2>&1 ; then
      ddev wp user delete "${!user_name}" --yes ;
    else
      echo "   ${!user_name} is not there." ;
    fi
  done
  cd ${WORKSPACE_ROOT}/${doc_name};
}

# What cmd-tools-wordpress-cli.sh does: the first of --run, --update, --plugins, --themes,
# --add-users, --cancel-users that was asked for; with none of them, what the site is.
function wordpress_cli_tool() {
  trim_project_name ;
  wordpress_enter_project || exit 1 ;

  if ! ddev describe -j 2>/dev/null | grep -q '"status":"running"' ; then
    ddev start -y || exit 1 ;
  fi

  if [ ! "${RUN}" == '_none_' ] ; then
    # Unquoted on purpose: --run "plugin list --status=active" is a command and its arguments.
    ddev wp ${RUN} ;
    exit $? ;
  fi

  if [ "${UPDATE}" == 'yes' ] ; then
    ddev wp core update && ddev wp core update-db ;
    ddev wp plugin update --all ;
    ddev wp theme update --all ;
    ddev wp language core update ;
  elif [ "${PLUGINS}" == 'yes' ] ; then
    ddev wp plugin update --all ;
  elif [ "${THEMES}" == 'yes' ] ; then
    ddev wp theme update --all ;
  elif [ "${ADD_USERS}" == 'yes' ] ; then
    set_wordpress_users ;
    add_wordpress_users ;
  elif [ "${CANCEL_USERS}" == 'yes' ] ; then
    set_wordpress_users ;
    cancel_wordpress_users ;
  else
    echo "${doc_name}/${PROJECT_NAME}: WordPress $(ddev wp core version 2>/dev/null) at $(ddev wp option get siteurl 2>/dev/null)" ;
    echo "" ; echo "Plugins:" ; ddev wp plugin list --fields=name,status,version,update ;
    echo "" ; echo "Themes:" ; ddev wp theme list --fields=name,status,version,update ;
    echo "" ; echo "Accounts:" ; ddev wp user list --fields=user_login,user_email,roles ;
  fi
  cd ${WORKSPACE_ROOT}/${doc_name};
}

# The step pack in the testing stack of a WordPress project. The core's testing_configure calls
# this in the project folder once webship-js is scaffolded and before the dependencies are
# installed; for a project that is not WordPress it changes nothing.
#
# It adds the pack to package.json, lists its step definitions in cucumber.js after webship-js's
# own, gives cucumber.js the users registry of the default accounts (a handle a scenario reads,
# mapped to an account; never the workspace account), and writes a first feature when the project
# has none of its own. Every part is skipped when it is already there, so a second run adds what
# the first missed and never resets a suite.
function testing_configure_wordpress() {
  local project_path="$1";
  wordpress_is_project "${project_path}" || return 0 ;
  if [ ! -f "${project_path}/cucumber.js" ] || [ ! -f "${project_path}/package.json" ] ; then
    echo "  WordPress: cucumber.js is not here yet — run the testing setup again once webship-js is scaffolded." ;
    return 1 ;
  fi

  echo "Adding the WordPress step pack (${WORDPRESS_STEPS_PACKAGE} ${WORDPRESS_STEPS_VERSION}).";
  set_wordpress_users ;
  local registry="" user user_name user_password handle ;
  for user in "${users[@]}" ; do
    user_name="user_${user}_name"; user_password="user_${user}_password";
    # The pack's features call the administrator "admin".
    handle="${user}" ; [ "${user}" == 'administrator' ] && handle="admin" ;
    registry="${registry}${handle}|${!user_name}|${!user_password}"$'\n' ;
  done

  python3 - "${project_path}" "${WORDPRESS_STEPS_PACKAGE}" "${WORDPRESS_STEPS_VERSION}" 'WP' "${registry}" <<'PYEOF' || return 1
import json, re, sys

project, pack, version, prefix, registry = sys.argv[1:6]

# package.json: the pack as a dev dependency, at the release line this plugin was proven on.
pkg_file = project + '/package.json'
pkg = json.load(open(pkg_file))
if pack not in pkg.get('dependencies', {}) and pack not in pkg.get('devDependencies', {}):
    pkg.setdefault('devDependencies', {})[pack] = version
    open(pkg_file, 'w').write(json.dumps(pkg, indent=2) + '\n')
    print('  package.json: %s %s' % (pack, version))

# cucumber.js: the pack's step definitions after webship-js's own, and the users registry.
cucumber_file = project + '/cucumber.js'
src = open(cucumber_file).read()
before = src

if ('node_modules/%s/' % pack) not in src:
    line = "'node_modules/%s/tests/step-definitions/**/*.js'," % pack
    core = re.search(r"^([ \t]*)'node_modules/webship-js/tests/step-definitions/[^']*',.*$", src, re.M)
    opening = re.search(r"^([ \t]*)require:[ \t]*\[[ \t]*$", src, re.M)
    if core:
        src = src[:core.end()] + '\n' + core.group(1) + line + src[core.end():]
    elif opening:
        src = src[:opening.end()] + '\n' + opening.group(1) + '  ' + line + src[opening.end():]
    else:
        sys.exit("  cucumber.js has no require list this can add to. Add this line to it:\n    " + line)
    print('  cucumber.js: the step definitions of %s' % pack)

if not re.search(r"^[ \t]*users:[ \t]*\{", src, re.M):
    world = re.search(r"^([ \t]*)worldParameters:[ \t]*\{[ \t]*$", src, re.M)
    if not world:
        sys.exit("  cucumber.js has no worldParameters block to add the users registry to.")
    pad = world.group(1) + '  '
    rows = [r.split('|') for r in registry.splitlines() if r.strip()]
    block = [
        pad + "// The users registry: a handle a scenario reads, mapped to an account of this site (the default",
        pad + "// accounts: cmd-tools-add-users.sh). Override one with %s_<HANDLE>_USER and %s_<HANDLE>_PASSWORD." % (prefix, prefix),
        pad + "users: {",
    ]
    for handle, name, password in rows:
        env = '%s_%s' % (prefix, handle.upper())
        block.append(pad + "  %s: { username: process.env.%s_USER || '%s', password: process.env.%s_PASSWORD || '%s' }," % (handle, env, name, env, password))
    block.append(pad + "},")
    src = src[:world.end()] + '\n' + '\n'.join(block) + src[world.end():]
    print('  cucumber.js: the users registry (%s)' % ', '.join(r[0] for r in rows))

if src != before:
    open(cucumber_file, 'w').write(src)
PYEOF

  # A first feature, when the project has none for the site yet: the front page, the login screen,
  # each default account in its role.
  local feature="${WORKSPACE_SCRIPTS}/plugins/wordpress/site.feature" ;
  if [ -f "${feature}" ] && [ ! -f "${project_path}/tests/features/site.feature" ] ; then
    mkdir -p "${project_path}/tests/features" && cp "${feature}" "${project_path}/tests/features/site.feature" \
      && echo "  tests/features/site.feature: a first feature for the site" ;
  fi

  # The scenarios log in as the default accounts: make sure an installed site has them.
  if ddev wp core is-installed > /dev/null 2>&1 ; then
    ( add_wordpress_users > /dev/null ) && echo "  the default accounts are on the site (${users[*]})" ;
  fi
}
