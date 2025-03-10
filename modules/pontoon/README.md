<!-- SPDX-License-Identifier: Apache-2.0 -->

### Pontoon installation instructions

Pontoon operations are carried out on the command line by `pontoonctl`, for
example to create new hosts.

You will need a `puppet.git` checkout, and specifically the
`modules/pontoon/files` directory, where stack configurations are stored.


To install `pontoonctl` on your Debian system:

```sh
# Install dependencies
sudo apt install python3-novaclient python3-keystoneauth1 pipx
# Need to be in a directory with Pontoon stacks
cd <local puppet.git checkout>/modules/pontoon/files
git checkout production
# Run pontoonctl from puppet.git checkout
pipx install --system-site-packages --editable '.[ctl]'
# Note: make sure to have pipx >= 1.1.0 or --editable emits a warning
```

Check Cloud VPS connectivity with `pontoonctl list-hosts` and follow the
instructions to set up credentials.

> **Note:** Working and configured Cloud VPS access is assumed from this point on.
In other words, `ssh` towards `wikimedia.cloud` hosts must work. See also
[Cloud VPS access](https://wikitech.wikimedia.org/wiki/Help:Accessing_Cloud_VPS_instances)
for setup instructions.

## Quickstart

This section will help you get started with Pontoon. Make sure to visit [Pontoon
Wikitech page](https://wikitech.wikimedia.org/wiki/Puppet/Pontoon) for in depth
explanation of the concepts outlined here.

### SSH setup

Since `pontoonctl` establishes multiple SSH connections, users with SSH keys
stored on security tokens (e.g., YubiKey) may experience repeated access
prompts. To avoid this, configure SSH `ControlMaster` and `ControlPersist`
options.

For optional SSH hostname completion, add the following before the Cloud VPS
bastion configuration in `~/.ssh/config`:

```
Host *.wikimedia.cloud
  UserKnownHostsFile ~/.config/pontoon/ssh_known_hosts
```

### Create a new stack

The following instructions will guide you through creating a new stack,
bootstrap it and finally add new roles.

```sh
# Set the stack name for quickstart. Using -s / --stack is supported too
export PONTOON_STACK=$USER-quick
pontoonctl new-stack
# The stack is created, follow the instructions on screen, then
pontoonctl bootstrap-stack
```

After approximately ten minutes you will have:
* a Cloud VPS host named after your stack, serving as the Pontoon Puppet server
* the current git branch set `pontoon-STACK-NAME`
* a `git remote` named `pontoon-STACK-NAME`

The stack is bootstrapped and ready; the Puppet agent serves as its own server.
Push your local `puppet.git` commits to the git remote until you are happy with
the result and the commits are ready for code review.

#### Add PKI and PuppetDB roles

At this point you can add additional foundational services required to make most
roles work, namely PuppetDB and PKI.  These roles are grouped together and can
be added with the following:

```sh
pontoonctl add-rolegroup bootstrap
# Follow the instructions on screen
# NOTE the initial git push might take about half a minute
pontoonctl create-hosts    # will take about 5 minutes
pontoonctl wait-puppet    # will take about 20 minutes
```


Once Puppet has converged you now have a stack fully bootstrapped with a working
PuppetDB and PKI available. The stack is ready for any additional roles you want
to test.

### Join an existing stack

Existing and bootstrapped Pontoon stacks can be configured locally (i.e. joined)
by following the instructions of the following command:

```sh
pontoonctl join-stack --stack mystack # or set PONTOON_STACK
```

Once joining is completed you are ready to `git push` changes to your Pontoon stack.

### Shell auto-completion

`pontoonctl` supports shell completion via
[Click](https://click.palletsprojects.com/en/stable/shell-completion/). Enable
it for bash with:

```sh
source <(_PONTOONCTL_COMPLETE=bash_source pontoonctl)
```

Ensure `PONTOON_HOME` is set for `--stack` completion to work. Also, define
`PONTOON_STACK` to enable `--role` completion for discovering available roles
within your stack.

## Troubleshooting

### Python version upgrades

The `pipx`-managed virtualenv may break on python version upgrades. The fix is to nuke `$HOME/.local/share/pipx/venvs/pontoon` and create it again as described in the installation section.