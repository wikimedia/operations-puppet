<!-- SPDX-License-Identifier: Apache-2.0 -->

# Pontoon

The following document will guide you through installing `pontoonctl` and set up
your first stack. Please refer to the [wikitech Pontoon
page](https://wikitech.wikimedia.org/wiki/Puppet/Pontoon) for more context and
information.

## Installation

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

Check Cloud VPS connectivity with `pontoonctl list-hosts --scope project` and
follow the instructions to set up credentials.

> **Note:** Working and configured Cloud VPS access is assumed from this point on.
In other words, `ssh` towards `wikimedia.cloud` hosts must work. See also
[Cloud VPS access](https://wikitech.wikimedia.org/wiki/Help:Accessing_Cloud_VPS_instances)
for setup instructions.

## Quickstart

This section will help you get started with Pontoon. Make sure to visit [Pontoon
Wikitech page](https://wikitech.wikimedia.org/wiki/Puppet/Pontoon) for in depth
explanation of the concepts outlined here.

### SSH setup

> **Note:** Since `pontoonctl` establishes multiple SSH connections, make sure
you can `ssh` to CloudVPS hosts without prompts. Users with SSH keys stored
on security tokens (e.g., YubiKey) may experience repeated access prompts. To
avoid this, configure SSH `ControlMaster` and `ControlPersist` options.

Add the following before the Cloud VPS bastion configuration in `~/.ssh/config`:

```ssh-config
Host *.wikimedia.cloud
  UserKnownHostsFile ~/.config/pontoon/ssh_known_hosts
```

The snippet will ensure auto-completion for `ssh` hostnames and `git push`
towards Pontoon hosts works out of the box.

### Create a new stack

The following instructions will guide you through creating a new stack,
bootstrap it and finally add new roles.

```sh
# Set the stack name for quickstart. Using -s / --stack is supported too
export PONTOON_STACK=$USER-quick
pontoonctl new-stack
# The stack is created, follow the instructions on screen, then
pontoonctl bootstrap-stack    # will take about 10 minutes
```

In order to be able to run `pontoonctl` from any directory it is recommended to
set `PONTOON_HOME` to the directory containing stacks (i.e. the directory you
are in currently).

Once the bootstrap has completed you will have:

* a Cloud VPS host named after your stack, serving as the Pontoon Puppet server
* the current git branch set `pontoon-STACK-NAME`
* a `git remote` named `pontoon-STACK-NAME`

The stack is bootstrapped and ready; the Puppet agent serves as its own server.
You can now push your local `puppet.git` commits to the git remote until you are
happy with the result and the commits are ready for code review.

> **Note:** Remember to force-push your `HEAD` to the `production` remote branch:
> `git push -f pontoon-<STACK NAME> HEAD:production`

#### Add PKI and PuppetDB roles

At this point you can add additional foundational services required to make most
roles work, namely PuppetDB and PKI.  These roles are grouped together and can
be added with the following:

```sh
pontoonctl add-rolegroup bootstrap
# NOTE the initial git push might be slow, depending on your local internet
pontoonctl create-hosts    # will take about 5 minutes
pontoonctl wait-puppet    # will take about 20 minutes
```

Once Puppet has converged you now have a stack fully bootstrapped with a working
PuppetDB and PKI available. The stack is ready for any additional roles you want
to test.

#### Add your role to the stack

With your stack fully bootstrap you can now proceed to add your role. To do so,
edit your stack's `rolemap.yaml` and add the role and an host. Making sure to
keep the existing naming scheme of `stack prefix` + `role` + `integer`. For
example:

```yaml
myrole:
  - stackprefix-myrole-01.project.eqiad1.wikimedia.cloud
```

Then proceed to `git commit` the result and `git push -f pontoon-<STACK NAME>
HEAD:production` to your stack.

Finally, kick off `pontoonctl create-hosts`.  Once that is done you can `ssh
hostprefix-myrole-01.project.eqiad1.wikimedia.cloud` and run puppet to inspect
the result.

Depending on the role the default VM specs may be enough, if not make sure to
adjust them in `specmap.yaml`.

Getting new roles to work in Pontoon may require tweaks to hiera and/or puppet
code. Navigate to [wikitech
documentation](https://wikitech.wikimedia.org/wiki/Puppet/Pontoon#Make_roles_work_in_Pontoon)
for more detailed instructions and reach out via Phabricator [#pontoon
project](https://phabricator.wikimedia.org/project/view/6192/) for assistance.

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

The `pipx`-managed virtualenv may break on python version upgrades. The fix is
to `rm -rf $HOME/.local/pipx/venvs/pontoon` and create it again as described
in the [installation section](#installation).

### Installation non-Debian systems

You can also run `pontoonctl` with `pipx` managing all its dependencies. You
will need `pipx >= 1.1.0` and use the following to install:

```sh
pipx install --editable '.[ctl]'
```

## Tips and tricks

### Private Puppet repo

It is possible to also have changes to the [private puppet
repo](https://gerrit.wikimedia.org/g/labs/private) in Pontoon.
To do so, follow the private.git instructions setup:

```sh
# Command is idempotent, can be re-run at will
pontoonctl join-stack --stack <STACK NAME>
```

And push your local copy of `private.git` with:

`git push -f pontoon-<STACK NAME>-private HEAD:master`

Note that here we push to the `master` branch, not the `production` branch.

### Test network changes

As of December 2025 Cloud VPS uses `systemd-networkd` to manage network
interfaces while production uses `ifupdown`. The recommended way to bridge this
gap is to set up dummy network interface(s) for `ifupdown` to manage:

```sh
ip link add dummy0 type dummy
```

And reference said dummy interfaces in Puppet code, as opposed to the
`systemd-networkd`-managed VM interfaces.

## Development

> **Note:**  `PONTOON_HOME` is set to the source code in `<puppet.git>/modules/pontoon/files`.

### Testing

Use the `dev` dependencies to set up the virtual environment:

```sh
cd $PONTOON_HOME
pipx install --editable '.[dev]' --force
```

Then run the virtual env's `pytest`:

```sh
~/.local/pipx/venvs/pontoon/bin/pytest
```

### Integration tests

The integration tests exercise the unattended bootstrap of a Pontoon stack
including PuppetDB and PKI. Cloud credentials are required for VMs to be created
and they need to be set in `PONTOON_CLOUD_ID` and `PONTOON_CLOUD_SECRET`.

```sh
cd $PONTOON_HOME
# Takes in the order of half an hour
~/.local/pipx/venvs/pontoon/bin/pytest -m integration
```
