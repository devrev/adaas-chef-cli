# chef-cli

DevRev auxiliary CLI for Airdrop snap-in recipe development.

General Airdrop snap-in documentation: https://developer.devrev.ai/airdrop

chef-cli documentation: https://developer.devrev.ai/airdrop/initial-domain-mapping

## Install chef-cli

Under [releases](https://github.com/devrev/adaas-chef-cli/releases), select the binary appropriate for your operating system, and install it in your path (or remember its location). 
In the following steps we will assume it is available as `$ chef-cli`

### Install auto-completions

To install auto-completions on Linux or Mac, you can run:

```bash
./install_completions.sh
```

And restart your shell.

We support Bash and ZSH. Make sure to run the script from project home directory.

To install PowerShell auto-completions, first run `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`. 
Then open the PowerShell profile (with `code $profile` or `notepad $profile`) and add this line (make sure to replace `/path/to/this/repo` with the path to this repository):

```text
/path/to/this/repo/autocomplete/chef-cli.ps1
```
