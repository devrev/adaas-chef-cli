# Chef-cli initial domain mapping setup

## Prerequisites

- Snap-in is set up, deployed, and activated
- An import has been created and is in the mapping stage

It's also recommended that you have the DevRev CLI authenticated appropriately. This can be done either with `devrev profiles authenticate -e prod -o <your org slug> -u <your email>` or by running `make auth` in your snap-in repository.

## Add your token as an environment variable
   
Obtain a PAT-token from the Settings/Account tab of the devorg where you deploy your snap-in, and export is at DEVREV_TOKEN. 

You can also run the following command if you are authenticated with the CLI:
 ```bash
export DEVREV_TOKEN=$(devrev profiles get-token access)
```

## Initialize the context of the sync

To allow the cli to work in the context of that sync, you have to provide its identifying properties in an environment variable.
The recommended method is to run:

```bash
chef-cli ctx switch --env prod
```

This will print the list of airdrop imports in the org. Select the one you like by running

```bash
eval $(chef-cli ctx switch --env prod --id <the id you choose>); chef-cli ctx show
```

If this method doesn't work, you can manually export the variable (replacing the values based on the logs of your running import):

```bash
export AIRDROP_CONTEXT='{"run_id":"1","mode":"initial","connection_id":"x","migration_unit_id":"0716","dev_org_id":"DEV-1kA79wWrRR","dev_user_id":"DEVU-1","source_id":"07-16","source_type":"ADaaS","source_unit_id":"x","source_unit_name":"x","import_slug":"x","snap_in_slug":"x"}'
```

Or you can use the interactive helper of the cli:

```bash
eval $(chef-cli ctx init); chef-cli ctx show > ctx.json
```

## Use the local UI to create a recipe blueprint for your initial import

```bash
chef-cli configure-mappings --env prod
```

If you are also creating DevRev -> external system sync, use:
```bash
$ chef-cli configure-mappings --env prod --reverse
```

Which enables mapping in both directions.

If your org is not in US-East-1, you have to override an environment variable to make sure the tool reaches to the right server, eg:

```bash
ACTIVE_PARTITION=dvrv-in-1 chef-cli configure-mappings --env prod
```

where the options are:
"dvrv-us-1"
"dvrv-eu-1"
"dvrv-in-1"
"dvrv-de-1"

The first function of the local UI is to assemble a 'blueprint' for concrete import running in the test-org, allowing the mapping to be tested out and evaluated.
After it is used for the import, the mappings become immutable, but the chef-cli UI offers a button to make a draft clone, which can be edited again for refinements.

## Continue to initial domain mapping

You can now use the chef-cli web UI to create initial domain mappings.
