Write and run webship-js scenarios for what one role does on a WordPress site.

```
claude --permission-mode bypassPermissions """
Write scenarios for what the <administrator|editor|author|contributor|subscriber> does on this site, and run them
# ~/workspace/<folder>/<site> · https://<site>.ddev.site · container-based (DDEV by default)
# use the wordpress-scenarios skill for the phrases, and the wordpress-tester agent if you hand the work over
# use playwright mcp, in a tab of your own, to do each thing by hand once before writing its scenario

What to cover:
<the screens and tasks of this role that matter here, one per line>

Read the installed steps first:
grep -hE '^(Given|When|Then)\(' node_modules/@webship-js/wordpress-steps/tests/step-definitions/*.steps.js

Write one feature in tests/features/<role>.feature, from phrases that exist.
Log in by the handle of the users registry (admin, editor, author, contributor, subscriber):
no password in the feature, no account created by a scenario, no platform name in a step phrase.
What a scenario creates, it removes in the same scenario.

Then, from the sites folder (cd ..):
bash cmd-tools-testing.sh <site> --dry-run --path tests/features/<role>.feature
bash cmd-tools-testing.sh <site> --run --path tests/features/<role>.feature

A failing scenario is a result: tell me what the site did, do not loosen the scenario.
When you are done: the scenarios, the result of the run, and any step you could not find in the pack
"""
```
