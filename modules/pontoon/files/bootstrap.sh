#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

# Bootstrap a Pontoon Puppet server from a provisioned host, using public git repos.
# At the end of this phase the host must be ready to:
# * accept new Puppet agents
# * receive git changes from user(s)

set -e
set -u

FQDN=$(hostname --fqdn)

preflight() {
  if [ -z "${SUDO_USER:-}" ]; then
    echo "Please bootstrap using sudo (or set SUDO_USER)"
    exit 2
  fi

  if ! which puppet; then
    echo "'puppet' command not found, has the host been provisioned?"
    exit 2
  fi

  if [ -z "$FQDN" ]; then
    echo "Unable to determine FQDN"
    exit 2
  fi

  apt install -y --no-install-recommends git ca-certificates

  # Workaround dummy 'apache2.conf' in WMCS
  if [ -e /etc/apache2/apache2.conf ] && ! dpkg -s apache2 >/dev/null 2>&1; then
    rm /etc/apache2/apache2.conf
  fi
}

clone_repos() {
  local dir=$1

  pushd .
  cd "$dir"
  [ ! -d puppet ] && git clone --depth=1 https://gerrit.wikimedia.org/r/operations/puppet
  [ ! -d private ] && git clone --depth=1 https://gerrit.wikimedia.org/r/labs/private
  popd
}

# Bootstrap a role::puppetmaster::pontoon by writing minimal manifests to
# $init, using modules from $git (i.e. public repos) and kick off a "puppet apply"
bootstrap_server() {
  local git=$1
  local init=$2

  install -v $git/puppet/manifests/realm.pp $init/00realm.pp
  cat <<EOF > $init/bootstrap.pp
\$_role = 'puppetmaster/pontoon'
\$pontoon_bootstrap = true
include "role::puppetmaster::pontoon"
EOF

  sed -e "s@/etc/puppet/hieradata@$git/puppet/hieradata@" \
    -e "s@/etc/puppet/private@$git/private@" \
    $git/puppet/modules/puppetmaster/files/hiera/pontoon.yaml > $init/hiera.yaml


  install -d $git/puppet/hieradata/pontoon
  cat <<EOF > $git/puppet/hieradata/pontoon/bootstrap.yaml
bastion_hosts:
  - 0.0.0.0/0

profile::resolving::nameservers:
  - 8.8.8.8

profile::base::manage_resolv_conf: false

puppetmaster: $FQDN
puppet_ca_server: $FQDN
EOF
  systemctl mask puppet-master

  puppet apply --hiera_config $init/hiera.yaml \
    --modulepath $git/puppet/modules:$git/puppet/vendor_modules:$git/private/modules \
    --verbose --detailed-exitcodes \
    $init || true # XXX catch failures?

  # Solve race on hieradata/auto.yaml
  install -o puppet -g puppet -m 644 /dev/null /etc/puppet/hieradata/auto.yaml
}

init_ssl() {
  # Init the CA
  timeout 10 puppet master --no-daemonize --verbose || true

  # No need for separate 'server' ssldir and client
  if [ ! -L /var/lib/puppet/ssl ]; then
    rm -rf /var/lib/puppet/ssl
    ln -s /var/lib/puppet/server/ssl /var/lib/puppet/ssl
  fi

  install -d -o puppet /var/lib/puppet/reports
  chown -R puppet /var/lib/puppet/reports
}

bootstrap_private() {
  local git=$1

  install -d /var/lib/git/labs
  rsync -a ${git}/private /var/lib/git/labs
}

init_user_repos() {
  local user=$1

  local puppet_repo=/var/lib/git/operations/puppet
  local private_repo=/var/lib/git/labs/private

  (
    su "$user" -c "
    set -e

    cd
    if [ ! -d puppet.git ]; then
      git clone --bare --no-hardlinks --branch production $puppet_repo puppet.git
    fi
    install -v -m755 ${puppet_repo}/modules/puppetmaster/files/self-master-post-receive \
      puppet.git/hooks/post-receive

    if [ ! -d private.git ]; then
      git clone --bare --no-hardlinks --branch master $private_repo private.git
    fi
    install -v -m755 ${puppet_repo}/modules/puppetmaster/files/self-master-post-receive \
      private.git/hooks/post-receive

    echo; echo; echo
    echo \"  Bare puppet repository initialized at $PWD/puppet.git\"
    echo
    echo \"  Bare private repository initialized at $PWD/private.git\"
    "
  )
}

instructions() {
  cat <<EOF


  The host ${FQDN} is ready to receive puppet changes.

  In order to create the new stack '${stack}' you will need to assign the
  'puppetmaster::pontoon' role to this host, commit the result and push the
  commit to remote ${git_remote_name}.

  Run the following commands from a local checkout of puppet.git on your
  computer to get started:

# remote setup
git remote add ${git_remote_name} ssh://${FQDN}/~/puppet.git

# add the stack's rolemap and commit changes
git checkout -b pontoon-$stack production

mkdir modules/pontoon/files/${stack}
printf "puppetmaster::pontoon:\n  - ${FQDN}\n" > modules/pontoon/files/${stack}/rolemap.yaml

git add modules/pontoon/files/${stack}
git commit -m "pontoon: initialize new stack ${stack}"

# push the changes as 'production' branch to the remote
git push -f ${git_remote_name} HEAD:production

# switch the server to ${stack}
ssh ${FQDN} "echo ${stack} | sudo tee /etc/pontoon-stack"


  You can refer to these instructions later at ${FQDN}:${readme}

  For more information make sure to check out Pontoon in Wikitech:
  https://wikitech.wikimedia.org/wiki/Puppet/Pontoon


EOF
}


stack=${1:-}
if [ -z "$stack" ]; then
  echo "usage: $(basename $0) stack"
  exit 1
fi

git_remote_name="pontoon-$stack"
readme=/etc/README.pontoon

preflight
install -d /tmp/bootstrap/git /tmp/bootstrap/init
clone_repos /tmp/bootstrap/git
echo bootstrap > /etc/pontoon-stack
bootstrap_server /tmp/bootstrap/git /tmp/bootstrap/init
bootstrap_private /tmp/bootstrap/git
init_ssl

systemctl restart apache2

init_user_repos $SUDO_USER

instructions | tee $readme
