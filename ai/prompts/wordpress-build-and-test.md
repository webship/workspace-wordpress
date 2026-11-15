Build a WordPress site in a sites folder and prove it with its first webship-js feature.

The launch command below is for Claude Code, the default; the text between the triple quotes can be given to another AI CLI as it is.

```
claude --permission-mode bypassPermissions """
Build a WordPress site named <name> in this sites folder and test it with webship-js
# ~/workspace/<dev|test|sandboxes|demos> · https://<name>.ddev.site · container-based (DDEV by default)
# the builder deletes a project of the same name first: stop if <name> is a site somebody still needs
# nothing on the host: no wp, composer, npm or mysql outside the site's container

1. bash cmd-wordpress-project.sh <name> --install --add-users
   (add --version <x> for a release other than the latest)
2. bash cmd-tools-wordpress-cli.sh <name>
   tell me the version, the address, the theme that is active and the accounts it lists
3. bash cmd-tools-testing.sh <name>
   webship-js, the step pack, the users registry and tests/features/site.feature
4. bash cmd-tools-testing.sh <name> --dry-run --path tests/features/site.feature
5. bash cmd-tools-testing.sh <name> --run --path tests/features/site.feature

If a command fails, show the line that failed and stop. Do not retry with other flags.
When the feature is green: the address, the version, how many scenarios and steps passed.
Then ask me whether to keep the site or remove it with: bash cmd-tools-remove.sh <name>
"""
```
