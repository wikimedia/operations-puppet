#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

# Bootstrap a Pontoon Puppet server from a provisioned host.
# Code will be cloned from public repos (puppet.git/private.git).
# Optionally users can provide their own code in $HOME/bootstrap/{puppet,private}
#
# At the end of this phase the host must be ready to:
# * accept new Puppet agents
# * receive git changes from user(s) for puppet and private repos

set -e
set -u

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

  apt install -y --no-install-recommends git ca-certificates rsync gettext-base

  apt-get satisfy -y 'puppet (>= 7)'

  # Make sure agent ssl material is refreshed at the next puppet run, unless
  # we've already finished bootstrapping (i.e. first run has happened and the
  # puppetserver CA has a signed cert)
  if [ ! -e /etc/puppet/puppetserver/ca/signed/$FQDN.pem -a -e /var/lib/puppet/ssl ]; then
    rm -rf /var/lib/puppet/ssl
  fi

  install -d /srv/git
}

git_init() {
  local orig_dir=$1
  local dir=$2

  if [ -d "$dir/.git" ]; then
    return
  fi

  pushd $dir
  git init --initial-branch production --quiet
  git add .
  git commit --quiet --message "Bootstrapped from $orig_dir"
  popd
}

# Init the repositories with user-provided code when requested.
# Since the code might not be a git repo, turn it into one as needed.
bootstrap_repos() {
  local dir=$1

  local user_home=$(getent passwd $SUDO_USER | cut -d: -f6)
  local user_puppet=$user_home/bootstrap/puppet
  local user_private=$user_home/bootstrap/private

  if [ -d "$user_puppet" ]; then
    rsync -a --delete $user_puppet $dir
    git_init $user_puppet $dir/puppet
  fi

  if [ -d "$user_private" ]; then
    rsync -a --delete $user_private $dir
    git_init $user_private $dir/private
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

# Bootstrap a role::puppetserver::pontoon via 'puppet apply'.
# The $init directory contains the manifests to apply and a 'run' script,
# whereas code/hiera come from repos checked out in $git.
bootstrap_server() {
  local git=$1
  local init=$2

  local puppet=$git/puppet
  local private=$git/private

  install -v -m644 $puppet/manifests/realm.pp $init/00realm.pp

  # Mini manifest to kick off bootstrap, role assignment will be replaced by the
  # Pontoon ENC afterwards.
  cat > $init/bootstrap.pp << EOF
node "$FQDN" {
  role(puppetserver::pontoon)
}
EOF

  # Hiera configuration and variables from 'bootstrap' stack
  env \
    PUPPET_REPO=$puppet \
    PRIVATE_REPO=$private \
    BOOTSTRAP_PATH=$init \
    envsubst \
    < $puppet/modules/pontoon/files/bootstrap/hiera-config.yaml \
    > $init/hiera-config.yaml

  env \
    FQDN=$FQDN \
    envsubst \
    < $puppet/modules/pontoon/files/bootstrap/hiera-vars.yaml \
    > $init/hiera-vars.yaml

  modulepath=$puppet/modules:$puppet/vendor_modules:$puppet/core_modules:$private/modules

  cat > $init/run << EOF
#!/bin/bash
export PONTOON_HOME=$puppet/modules/pontoon/files

exec puppet apply --hiera_config $init/hiera-config.yaml \\
  --modulepath $modulepath \\
  --verbose --detailed-exitcodes \\
  "\$@" $init
EOF

  chmod a+x $init/run
  set +e
  $init/run
  run_exitcode=$?
  set -e

  if [ "$run_exitcode" -eq 1 ]; then
    echo "$init/run failed with $run_exitcode"
    exit $run_exitcode
  fi
}

bootstrap_private() {
  local git=$1

  install -d /srv/git/labs
  rsync -a --chown puppet:root ${git}/private /srv/git/labs
}

FQDN=$(hostname --fqdn)
CHECK_ONLY=0

TEMP=$(getopt -o dp: --long debug,check -n "$0" -- "$@")
# shellcheck disable=SC2181
if [ "$?" != 0 ]; then
  echo "Terminating..." >&2
  exit 1
fi

eval set -- "$TEMP"
while true; do
  case "$1" in
  -d | --debug)
    set -x
    shift
    ;;
  --check)
    CHECK_ONLY=1
    shift
    ;;
  --)
    shift
    break
    ;;
  *)
    echo 'Internal error!' >&2
    exit 1
    ;;
  esac
done

STACK=${1:-}
if [ -z "$STACK" ]; then
  echo "usage: $(basename $0) STACK"
  exit 1
fi

repos_path=/tmp/bootstrap/git
init_path=/tmp/bootstrap/init
pontoon_path=/etc/pontoon

if [ -e $pontoon_path/bootstrap-ok ]; then
  exit 2
fi

if [ "$CHECK_ONLY" -eq 1 ]; then
  exit 0
fi

preflight

install -d $repos_path
bootstrap_repos $repos_path
clone_repos $repos_path

# The 'bootstrap' stack is used here temporarily
install -d $init_path $pontoon_path
echo bootstrap > $pontoon_path/stack
bootstrap_server $repos_path $init_path
bootstrap_private $repos_path

# The requested stack can be set now
echo $STACK > $pontoon_path/stack

touch $pontoon_path/bootstrap-ok
