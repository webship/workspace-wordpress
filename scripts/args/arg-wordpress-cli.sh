#!/usr/bin/env bash

argparse "$@" <<ARGEOF || exit 1
parser.add_argument('PROJECT_NAME',
                    help='The WordPress project in this workspace.')
parser.add_argument('-r', '--run',
                    default="_none_",
                    help='A WP-CLI command to run in the project, without the leading wp. Example: --run "plugin list --status=active"')
parser.add_argument('-u', '--update',
                    action='store_true',
                    default=False,
                    help='Update WordPress itself, its database, every plugin, every theme and the translations.')
parser.add_argument('-p', '--plugins',
                    action='store_true',
                    default=False,
                    help='Update every plugin, and nothing else.')
parser.add_argument('-t', '--themes',
                    action='store_true',
                    default=False,
                    help='Update every theme, and nothing else.')
parser.add_argument('-a', '--add-users',
                    action='store_true',
                    default=False,
                    help='Add the default accounts, one per role. An account that is already there is left as it is.')
parser.add_argument('-c', '--cancel-users',
                    action='store_true',
                    default=False,
                    help='Delete the default accounts and what they wrote.')
ARGEOF
