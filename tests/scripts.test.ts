import test from 'node:test';
import assert from 'node:assert';
import fs from 'fs';
import os from 'os';
import path from 'path';
import { spawnSync } from 'child_process';

// Compiled, these tests run from dist/tests, so the package root is one folder further up.
const PKG = fs.existsSync(path.join(__dirname, '..', 'package.json')) ? path.join(__dirname, '..') : path.join(__dirname, '..', '..');
const FUNCTIONS = path.join(PKG, 'scripts', 'functions', 'fun-wordpress.sh');

// The cucumber.js webship-js scaffolds, as far as the testing hook reads it.
const SCAFFOLD = `module.exports = {
  default: {
    requireModule: ['ts-node/register'],
    require: [
      'node_modules/webship-js/tests/step-definitions/**/*.js',          // Webship-js core step definitions.
      'tests/step-definitions/**/*.js',                                  // Your custom step definitions.
    ],
    paths: ['tests/features/**/*.feature'],
    worldParameters: {
      launchUrl: process.env.LAUNCH_URL || 'http://localhost:8080',
    },
  },
};
`;

/** A project folder with the testing stack scaffolded, and the tooling folder the installer would have filled. */
function project(type: string) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'wp-plugin-'));
  const dir = path.join(root, 'dev', 'site1');
  fs.mkdirSync(path.join(dir, '.ddev'), { recursive: true });
  fs.writeFileSync(path.join(dir, '.ddev', 'config.yaml'), `name: site1\ntype: ${type}\ndocroot: ""\n`);
  fs.writeFileSync(path.join(dir, 'cucumber.js'), SCAFFOLD);
  fs.writeFileSync(path.join(dir, 'package.json'), JSON.stringify({ name: 'site1', devDependencies: { 'webship-js': '^2.0.6' } }, null, 2));
  const scripts = path.join(root, 'core', 'scripts');
  fs.mkdirSync(path.join(scripts, 'plugins', 'wordpress'), { recursive: true });
  fs.copyFileSync(path.join(PKG, 'testing', 'site.feature'), path.join(scripts, 'plugins', 'wordpress', 'site.feature'));
  return { root, dir, scripts };
}

/** Run bash with the plugin's functions sourced and `ddev` replaced by a recorder. */
function bash(script: string, env: Record<string, string> = {}) {
  const r = spawnSync('bash', ['-c', `ddev() { echo "ddev $*" >> "\${DDEV_LOG:-/dev/null}" ; [ "$1 $2 $3" == "wp core is-installed" ] && return 0 ; [ "$1 $2 $3" == "wp user get" ] && return 1 ; return 0 ; }\nsource ${FUNCTIONS}\n${script}`],
    { encoding: 'utf8', env: { ...process.env, ...env } });
  return r;
}

test('the default accounts are one per role, with example addresses', () => {
  const r = bash('set_wordpress_users ; for u in "${users[@]}" ; do n="user_${u}_name" ; m="user_${u}_mail" ; p="user_${u}_password" ; l="user_${u}_role" ; echo "${!n}|${!m}|${!p}|${!l}" ; done');
  assert.strictEqual(r.status, 0, r.stderr);
  const rows = r.stdout.trim().split('\n').map((l) => l.split('|'));
  assert.deepStrictEqual(rows.map((x) => x[0]), ['administrator', 'editor', 'author', 'contributor', 'subscriber']);
  for (const [name, mail, password, role] of rows) {
    assert.strictEqual(mail, `${name}@example.com`);
    assert.strictEqual(role, name);
    assert.ok(password.length >= 8);
  }
});

test('the testing hook adds the step pack, the users registry and a first feature to a WordPress project, once', () => {
  const p = project('wordpress');
  const log = path.join(p.root, 'ddev.log');
  const run = () => bash(`cd ${p.dir} && testing_configure_wordpress ${p.dir}`, { WORKSPACE_ROOT: p.root, WORKSPACE_SCRIPTS: p.scripts, doc_name: 'dev', PROJECT_NAME: 'site1', DDEV_LOG: log });
  const r = run();
  assert.strictEqual(r.status, 0, r.stderr + r.stdout);
  const pkg = JSON.parse(fs.readFileSync(path.join(p.dir, 'package.json'), 'utf8'));
  assert.strictEqual(pkg.devDependencies['@webship-js/wordpress-steps'], '^2.2.0');
  assert.strictEqual(pkg.devDependencies['webship-js'], '^2.0.6', 'what was there stays');
  const cucumber = fs.readFileSync(path.join(p.dir, 'cucumber.js'), 'utf8');
  const lines = cucumber.split('\n');
  const core = lines.findIndex((l) => l.includes('node_modules/webship-js/tests/step-definitions'));
  assert.strictEqual(lines[core + 1], "      'node_modules/@webship-js/wordpress-steps/tests/step-definitions/**/*.js',", 'the pack is listed right after webship-js');
  assert.match(cucumber, /admin: \{ username: process\.env\.WP_ADMIN_USER \|\| 'administrator', password: process\.env\.WP_ADMIN_PASSWORD \|\| '[^']+' \},/);
  assert.match(cucumber, /subscriber: \{ username: process\.env\.WP_SUBSCRIBER_USER \|\| 'subscriber'/);
  // Still a module node can load, with the registry where webship-js reads it.
  const loaded = spawnSync(process.execPath, ['-e', `const c = require(${JSON.stringify(path.join(p.dir, 'cucumber.js'))}).default; console.log(JSON.stringify([c.require, Object.keys(c.worldParameters.users)]))`], { encoding: 'utf8' });
  assert.strictEqual(loaded.status, 0, loaded.stderr);
  const [requires, handles] = JSON.parse(loaded.stdout);
  assert.strictEqual(requires.length, 3);
  assert.deepStrictEqual(handles, ['admin', 'editor', 'author', 'contributor', 'subscriber']);
  assert.ok(fs.existsSync(path.join(p.dir, 'tests', 'features', 'site.feature')));
  assert.match(fs.readFileSync(log, 'utf8'), /ddev wp user create editor editor@example\.com --role=editor/, 'an installed site gets the default accounts');
  // Again, after a person changed the feature: nothing is doubled, nothing is reset.
  fs.writeFileSync(path.join(p.dir, 'tests', 'features', 'site.feature'), 'Feature: mine\n');
  assert.strictEqual(run().status, 0);
  assert.strictEqual(fs.readFileSync(path.join(p.dir, 'cucumber.js'), 'utf8'), cucumber);
  assert.strictEqual(fs.readFileSync(path.join(p.dir, 'tests', 'features', 'site.feature'), 'utf8'), 'Feature: mine\n');
});

test('the testing hook leaves a project of another platform alone', () => {
  const p = project('drupal11');
  const r = bash(`cd ${p.dir} && testing_configure_wordpress ${p.dir}`, { WORKSPACE_ROOT: p.root, WORKSPACE_SCRIPTS: p.scripts, doc_name: 'dev', PROJECT_NAME: 'site1' });
  assert.strictEqual(r.status, 0);
  assert.strictEqual(r.stdout, '');
  assert.strictEqual(fs.readFileSync(path.join(p.dir, 'cucumber.js'), 'utf8'), SCAFFOLD);
  assert.ok(!fs.existsSync(path.join(p.dir, 'tests')));
});

test('the CLI tool refuses a project that is not WordPress', () => {
  const p = project('drupal11');
  const r = bash('PROJECT_NAME=site1 ; RUN="plugin list" ; trim_project_name() { :; } ; wordpress_cli_tool', { WORKSPACE_ROOT: p.root, doc_name: 'dev' });
  assert.strictEqual(r.status, 1);
  assert.match(r.stdout, /is not a WordPress project/);
});

test('the first feature names no platform in a step, and no password', () => {
  const feature = fs.readFileSync(path.join(PKG, 'testing', 'site.feature'), 'utf8');
  const steps = feature.split('\n').filter((l) => /^\s*(Given|When|Then|And|But) /.test(l));
  assert.ok(steps.length >= 10);
  for (const s of steps) assert.doesNotMatch(s, /wordpress/i, s);
  assert.doesNotMatch(feature, /password "/);
  assert.doesNotMatch(feature, /user create|I register/i, 'a suite never creates an account');
});

// ---- The runtimes (#27): DDEV as before, and Docker Compose, Podman and Kubernetes through the core's layer ----

/**
 * Run the builder's function in a throwaway workspace with `ddev` replaced by a recorder, and the core's helpers by
 * stand-ins. `layer` is the runtime the core's layer answers with (runtime_of, rt_url, rt_is_platform), or '' for a
 * core that has no layer yet.
 */
function build(layer: string, env: Record<string, string> = {}) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'wp-build-'));
  fs.mkdirSync(path.join(root, 'dev'));
  const log = path.join(root, 'ddev.log');
  const address = layer === 'kubernetes' ? 'http://172.18.0.2:30080' : 'http://127.0.0.1:41234';
  const prelude = [
    `ddev() { echo "ddev $*" >> "${log}" ; [ "$1 $2 $3" == "wp config create" ] && cat > "${root}/extra.php" ; [ "$1 $2 $3" == "wp user get" ] && return 1 ; return 0 ; }`,
    'trim_project_name() { :; } ; drop_database() { :; } ; ddev_nodejs_version() { echo 24 ; } ; ddev_up() { ddev "$@" ; }',
    layer ? `runtime_of() { echo "\${RUNTIME_ANSWER}" ; } ; rt_url() { [ "\${RUNTIME_ANSWER}" == ddev ] && echo "https://\${PROJECT_NAME}.ddev.site" || echo "${address}" ; }` : '',
    `source ${FUNCTIONS}`,
    'wordpress_build',
  ].join('\n');
  const r = spawnSync('bash', ['-c', prelude], { encoding: 'utf8', env: { ...process.env, WORKSPACE_ROOT: root, doc_name: 'dev', PROJECT_NAME: 'site1',
    INSTALL: 'yes', ADD_USERS: 'no', LAUNCH: 'no', VERSION: 'latest', LOCALE: 'en_US', RUNTIME: '_none_', RUNTIME_ANSWER: layer || 'ddev',
    account_name: 'webmaster', account_pass: 'CHANGE_ME', account_mail: 'webmaster@example.com', ...env } });
  const calls = fs.existsSync(log) ? fs.readFileSync(log, 'utf8').trim().split('\n') : [];
  return { r, calls, dir: path.join(root, 'dev', 'site1'), root };
}

const DDEV_BUILD = [
  'ddev config --project-type=wordpress --docroot= --project-name=site1 --nodejs-version=24 --auto',
  'ddev start -y',
  'ddev wp core download --version=latest --locale=en_US',
  'ddev wp core install --url=https://site1.ddev.site --title=dev site1 --admin_user=webmaster --admin_password=CHANGE_ME --admin_email=webmaster@example.com --skip-email',
  'ddev wp rewrite flush',
  'ddev wp core version',
];

test('on DDEV the build is what it was: the same commands, the ddev.site address, no file written by the builder', () => {
  // A core with the runtime layer, and one from before it: the same build.
  for (const layer of ['ddev', '']) {
    const b = build(layer);
    assert.strictEqual(b.r.status, 0, b.r.stderr + b.r.stdout);
    assert.deepStrictEqual(b.calls, DDEV_BUILD, layer || 'no layer');
    assert.deepStrictEqual(fs.readdirSync(b.dir), [], 'DDEV writes wp-config.php; the builder writes nothing');
    assert.match(b.r.stdout, /Go to https:\/\/site1\.ddev\.site\/wp-admin and log in as webmaster/);
  }
});

test('on Docker Compose and Kubernetes the builder writes wp-config.php and .htaccess, and installs at the address of the runtime', () => {
  for (const [runtime, address] of [['docker', 'http://127.0.0.1:41234'], ['podman', 'http://127.0.0.1:41234'], ['kubernetes', 'http://172.18.0.2:30080']]) {
    const b = build(runtime, { RUNTIME: runtime });
    assert.strictEqual(b.r.status, 0, b.r.stderr + b.r.stdout);
    assert.deepStrictEqual(b.calls, [
      DDEV_BUILD[0], DDEV_BUILD[1], DDEV_BUILD[2],
      // The database of the project's own stack, and nothing personal.
      'ddev wp config create --dbname=db --dbuser=db --dbpass=db --dbhost=db --skip-check --extra-php',
      `ddev wp core install --url=${address} --title=dev site1 --admin_user=webmaster --admin_password=CHANGE_ME --admin_email=webmaster@example.com --skip-email`,
      'ddev wp option get permalink_structure',
      'ddev wp rewrite structure /%year%/%monthnum%/%day%/%postname%/',
      'ddev wp rewrite flush',
      'ddev wp core version',
    ], runtime);
    const extra = fs.readFileSync(path.join(b.root, 'extra.php'), 'utf8');
    assert.match(extra, /define\( 'WP_HOME', 'http:\/\/' \. \$_SERVER\['HTTP_HOST'\] \);/, 'the site answers at the address it is asked on');
    assert.doesNotMatch(extra, /ddev|127\.0\.0\.1|localhost/, 'no address is written into wp-config.php');
    const htaccess = fs.readFileSync(path.join(b.dir, '.htaccess'), 'utf8');
    assert.match(htaccess, /^# BEGIN WordPress\n<IfModule mod_rewrite\.c>\nRewriteEngine On\n/);
    assert.match(htaccess, /^RewriteRule \^index\\\.php\$ - \[L\]$/m);
    assert.match(htaccess, /^RewriteRule \. \/index\.php \[L\]\n<\/IfModule>\n# END WordPress\n$/m);
    assert.match(b.r.stdout, new RegExp(`Go to ${address.replace(/[.]/g, '\\.')}/wp-admin and log in as webmaster`));
    assert.doesNotMatch(b.r.stdout, /ddev\.site/);
  }
});

test('a wp-config.php or an .htaccess that is already there is left as it is', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'wp-config-'));
  fs.writeFileSync(path.join(root, 'wp-config.php'), '<?php // mine\n');
  fs.writeFileSync(path.join(root, '.htaccess'), '# mine\n');
  const log = path.join(root, 'ddev.log');
  const r = bash(`cd ${root} && wordpress_runtime_config`, { DDEV_LOG: log });
  assert.strictEqual(r.status, 0, r.stderr);
  assert.ok(!fs.existsSync(log), 'WP-CLI is not asked');
  assert.strictEqual(fs.readFileSync(path.join(root, 'wp-config.php'), 'utf8'), '<?php // mine\n');
  assert.strictEqual(fs.readFileSync(path.join(root, '.htaccess'), 'utf8'), '# mine\n');
});

test('--runtime on a workspace without the runtime layer is refused, never built on DDEV in silence', () => {
  const b = build('', { RUNTIME: 'docker' });
  assert.strictEqual(b.r.status, 1);
  assert.match(b.r.stdout, /--runtime docker needs a Webship Workspace with the container runtimes/);
  assert.deepStrictEqual(b.calls, [], 'nothing was configured or started');
  // Asking for DDEV by name is fine there.
  assert.strictEqual(build('', { RUNTIME: 'ddev' }).r.status, 0);
});

test('the builder takes --runtime, with the runtimes of the core\'s own builders', () => {
  const args = fs.readFileSync(path.join(PKG, 'scripts', 'args', 'arg-wordpress.sh'), 'utf8');
  assert.match(args, /parser\.add_argument\('--runtime',\s+dest='RUNTIME',\s+default="_none_",\s+choices=\['ddev', 'docker', 'podman', 'kubernetes'\],/);
});

test('a WordPress project is known on every runtime: the core\'s layer is asked when it is there', () => {
  // With the layer: its answer, for the folder and the plugin's name.
  const asked = bash('rt_is_platform() { echo "asked $1 $2" ; [ "$1" == /a/wp ] ; } ; wordpress_is_project /a/wp ; echo "rc=$?" ; wordpress_is_project /a/other ; echo "rc=$?"');
  assert.strictEqual(asked.stdout, 'asked /a/wp wordpress\nrc=0\nasked /a/other wordpress\nrc=1\n');
  // Without it: the DDEV project type, as before.
  const p = project('wordpress');
  assert.strictEqual(bash(`wordpress_is_project ${p.dir}`).status, 0);
  assert.strictEqual(bash(`wordpress_is_project ${project('php').dir}`).status, 1);
});

test('the tool and the test users work on a site of a runtime: no .ddev folder is asked for', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'wp-rt-'));
  const dir = path.join(root, 'dev', 'site1');
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(path.join(dir, 'compose.yaml'), 'name: site1\nx-webship:\n  runtime: docker\n  type: wordpress\n  port: 41234\n');
  const log = path.join(root, 'ddev.log');
  const layer = 'rt_is_platform() { grep -q "^  type: $2$" "$1/compose.yaml" ; } ; trim_project_name() { :; } ; ';
  const env = { WORKSPACE_ROOT: root, doc_name: 'dev', PROJECT_NAME: 'site1', DDEV_LOG: log };
  const add = bash(`${layer} set_wordpress_users ; add_wordpress_users`, env);
  assert.strictEqual(add.status, 0, add.stdout + add.stderr);
  assert.match(fs.readFileSync(log, 'utf8'), /ddev wp user create subscriber subscriber@example\.com --role=subscriber/);
  fs.unlinkSync(log);
  const run = bash(`${layer} RUN="plugin list" ; UPDATE=no ; wordpress_cli_tool`, env);
  assert.strictEqual(run.status, 0, run.stdout + run.stderr);
  assert.match(fs.readFileSync(log, 'utf8'), /ddev wp plugin list/);
});
