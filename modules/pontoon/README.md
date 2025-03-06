<!-- SPDX-License-Identifier: Apache-2.0 -->

### Pontoon installation instructions

Pontoon operations are carried out on the command line by `pontoonctl`, for
example to create new hosts.

You will need a `puppet.git` checkout, and specifically the
`modules/pontoon/files` directory, where stack configurations are stored.


To install `pontoonctl` on your Debian system:

    # Dependencies
    cd <local puppet.git checkout>/modules/pontoon/files
    sudo apt install python3-novaclient python3-keystoneauth1 pipx
    git checkout production
    # Run pontoonctl from puppet.git checkout
    pipx install --system-site-packages --editable '.[ctl]'
    # NOTE: make sure to have pipx >= 1.1.0 or --editable emits a warning

Check Cloud VPS connectivity with `pontoonctl list-hosts` and follow the
instructions to set up credentials.

**NOTE** Working and configured Cloud VPS access is assumed from this point on.
In other words `ssh` towards `wikimedia.cloud` hosts must work, see also
[Cloud VPS access](https://wikitech.wikimedia.org/wiki/Help:Accessing_Cloud_VPS_instances)
for setup instructions.

## Quickstart

This section will help you get started with Pontoon. Make sure to visit [Pontoon
Wikitech page](https://wikitech.wikimedia.org/wiki/Puppet/Pontoon) for in depth
explanation of the concepts outlined here.

### SSH setup

It is recommended and optional to setup SSH completion for Pontoon hostnames.
Place this before the Cloud VPS bastion configuration in your `~/.ssh/config`:

    Host *.wikimedia.cloud
      UserKnownHostsFile ~/.config/pontoon/ssh_known_hosts

### Create a new stack

The following instructions will guide you through creating a new stack, push
changes to it and add new roles.

    # Set the stack name for quickstart. Using -s / --stack is supported too
    export PONTOON_STACK=$USER-quick
    pontoonctl new-stack
    # The stack is created, follow the instructions on screen, then
    pontoonctl bootstrap-stack

If everything went well, after about ten minutes you have the following:
* a Cloud VPS host named after your stack, this is the Pontoon Puppet server
* a `git remote` set up named `pontoon-STACK-NAME`
* the current git branch is `pontoon-STACK-NAME`
* have just committed and `git push`-ed your first change to the stack

At this point the Pontoon Puppet server is bootstrapped. Your stack is now
functional and ready to accept roles.

#### Add PKI and PuppetDB roles

At this point you can add additional foundational services required to make most
roles work, namely PuppetDB and PKI.  These roles are grouped together and can
be added with the following:

    pontoonctl add-rolegroup bootstrap
    # Follow the instructions on screen
    # NOTE the initial git push might take about half a minute
    pontoonctl create-hosts
    # create-hosts is expected to take about five minutes
    pontoonctl wait-puppet
    # The initialization time for 'bootstrap' rolegroup is about twenty minutes

Once Puppet has converged you now have a stack fully bootstrapped with a working
PuppetDB and PKI available. The stack is ready for any additional roles you want
to test.

### Join an existing stack

Existing and bootstrapped Pontoon stacks can be configured locally (i.e. joined)
by following the instructions of the following command:

    pontoonctl join-stack --stack mystack # or set PONTOON_STACK

Once joining is completed you are ready to `git push` changes to your Pontoon stack.

### Shell auto completion

`pontoonctl` is powered by
[click](https://click.palletsprojects.com/en/stable/shell-completion/) and you
can for example enable shell completion with:

    source <(_PONTOONCTL_COMPLETE=bash_source pontoonctl)

Make sure to have `PONTOON_HOME` set for `--stack` completion to work.
Additionally, `PONTOON_STACK` must be set for `--role` to discover your stack's
roles.