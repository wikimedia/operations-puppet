### Pontoon installation instructions

Pontoon operations are carried out on the command line by `pontoonctl`, for
example to create new hosts.

You will need a `puppet.git` checkout, and specifically the
`modules/pontoon/files` directory, where stack configurations are stored.

**NOTE** while https://phabricator.wikimedia.org/T352640 is in progress, make
sure to `git checkout sandbox/filippo/pontoon-puppetserver`. This is the
development branch that will be merged in `production`. The branch gets `git push -f`
to and therefore you might see git complaining. If that happens, you can
`git reset --hard origin/sandbox/filippo/pontoon-puppetserver` to get the latest
changes.

To install `pontoonctl` on your Debian system:

    # Dependencies
    cd <local puppet.git checkout>/modules/pontoon/files
    sudo apt install python3-novaclient python3-keystoneauth1 pipx
    # See NOTE above re: using the sandbox branch
    git checkout sandbox/filippo/pontoon-puppetserver
    # Run pontoonctl from puppet.git checkout
    pipx install --system-site-packages --editable .[ctl]

Check Cloud VPS connectivity with `pontoonctl list-hosts` and follow the
instructions to set up credentials.

**NOTE** Working and configured Cloud VPS access is assumed from this point on.
In other words `ssh` towards `wikimedia.cloud` hosts must work, see also
[Cloud VPS access](https://wikitech.wikimedia.org/wiki/Help:Accessing_Cloud_VPS_instances)
for setup instructions.

## Quickstart

This section will help you get started with Pontoon. Make sure to visit [Pontoon Wikitech page](https://wikitech.wikimedia.org/wiki/Puppet/Pontoon) for in depth explanation of the concepts outlined here.

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

If everything went well, you now have the following:
* a Cloud VPS host named after your stack, this is the Pontoon Puppet server
* a `git remote` set up named `pontoon-STACK-NAME`
* the current git branch is `pontoon-STACK-NAME`
* have just committed and `git push`-ed your first change to the stack

At this point the Pontoon Puppet server is fully bootstrapped and your stack is funcional and ready to accept new roles.

#### Add PKI and PuppetDB roles

Most likely you want PKI and PuppetDB to be part of your stack too. Adding roles
to a stack is achieved by modifying the `rolemap.yaml` and assign hosts to
roles, for example:

    # edit $PONTOON_STACK/rolemap.yaml
    # make sure to keep the same host prefix as pontoon::puppetserver
    puppetdb:
      - <host prefix>-puppetdb-01.project.wikimedia.cloud
    pki::multirootca:
      - <host prefix>-pki-01.project.wikimedia.cloud

And the roles' hiera settings added to the stack:

    cd $PONTOON_STACK/hiera
    ln -s ../../settings/puppetdb.yaml
    ln -s ../../settings/pki.yaml

Next, `git add` and `git commit` the pending changes files, then `git push` to
the Pontoon remote as you did during bootstrap. The next step is to create the
new hosts and enroll them:

    pontoonctl create-hosts
    pontoonctl enroll-hosts --role puppetdb
    pontoonctl enroll-hosts --role pki::multirootca

### Join an existing stack

Existing and bootstrapped Pontoon stacks can be configured locally (i.e. joined) by following the instructions of the following command:

    pontoonctl join-stack -s mystack

Once joining is completed you are ready to `git push` changes to your Pontoon stack.
