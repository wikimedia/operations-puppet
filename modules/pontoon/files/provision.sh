#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

# Provision a new host with Debian installed.
# After this phase is complete the host must be ready to run puppet for the first time.

set -e
set -u

guard_file=/etc/.provision.done

preflight() {
  # Disable man-db rebuild on package installation
  debconf-set-selections <<EOF
man-db man-db/auto-update boolean false
EOF

  # XXX hack, make enroll.py happy
  install -d /var/lib/puppet/ssl

  apt install -y --no-install-recommends wget lsb-release locales
}

install_wmf_repo() {
  if [ ! -e /etc/apt/trusted.gpg.d/wikimedia-archive-keyring.gpg ]; then
    wget -O /etc/apt/trusted.gpg.d/wikimedia-archive-keyring.gpg \
      http://apt.wikimedia.org/autoinstall/keyring/wikimedia-archive-keyring.gpg
  fi

  if [ ! -e /etc/apt/preferences.d/wikimedia.pref ]; then
    echo -e 'Package: *\nPin: release o=Wikimedia\nPin-Priority: 1001\n' > /etc/apt/preferences.d/wikimedia.pref
  fi

  if [ ! -e /etc/apt/sources.list.d/wikimedia.list ]; then
    echo "deb http://apt.wikimedia.org/wikimedia $(lsb_release -s -c)-wikimedia main" > /etc/apt/sources.list.d/wikimedia.list
    apt -q update
  fi
}

provision_puppet() {
  apt install -y --no-install-recommends puppet

  puppet config set --section main vardir /var/lib/puppet
  puppet config set --section main rundir /var/run/puppet
  puppet config set --section main factpath \$vardir/lib/facter
}

setup_locale() {
  if ! grep -q '^en_US.UTF-8 UTF-8' /etc/locale.gen; then
    echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
    locale-gen
  fi
}

if [ -e $guard_file ]; then
  echo "Already provisioned: $(ls -la $guard_file)"
  exit 0
fi

preflight
install_wmf_repo
provision_puppet
setup_locale

touch $guard_file
