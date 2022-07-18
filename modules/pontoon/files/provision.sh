#!/bin/bash
# SPDX-License-Identifier: Apache-2.0

# Provision a new host with Debian installed.
# After this phase is complete the host must be ready to run puppet for the first time.

set -e
set -u

guard_file=/etc/.provision.done
# APT might be in use by some other provisioning processes, thus
# retry for up this many seconds
apt_deadline_seconds=60

preflight() {
  # Disable man-db rebuild on package installation
  debconf-set-selections <<EOF
man-db man-db/auto-update boolean false
EOF

  # XXX hack, make enroll.py happy
  install -d /var/lib/puppet/ssl

  _try_apt install -y --no-install-recommends \
      wget lsb-release locales augeas-tools jq
}


_try_apt() {
  start_ts=$(date +%s)

  while [ "$(date +%s)" -le "$(expr $start_ts + $apt_deadline_seconds)" ]; do
    if apt "$@"; then
      break
    fi

    sleep 5
  done
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
    _try_apt -q update
  fi
}

provision_puppet() {
  _try_apt install -y --no-install-recommends puppet

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

setup_az() {
  meta_file=$(mktemp)
  meta_url="http://169.254.169.254/metadata/instance?api-version=2021-02-01"

  trap "{ rm -f \"$meta_file\"; }" EXIT

  if ! curl -H Metadata:true --noproxy "*" "$meta_url" > "$meta_file"; then
    return
  fi

  environment=$(cat "$meta_file" | jq -r .compute.azEnvironment)
  if [ "$environment" != "AzurePublicCloud" ]; then
    return
  fi

  # The map(with_entries.. renames 'name' into 'key' so 'from_entries'
  # works on older (< Bullseye) jq versions
  domain=$(jq -r '.compute.tagsList | map(with_entries(if .key == "name" then .key = "key" else . end)) | from_entries | .domain' < "$meta_file")

  # Set (and persist) the custom domain name
  if [ ! -z "$domain" -a "$domain" != "null" ]; then
    _resolv_set_domain "$domain"
    _dhclient_override_domain "$domain"
  fi
}

_dhclient_override_domain() {
  local domain=$1
  local config=/etc/dhcp/dhclient.conf

  for opt in domain-name domain-search; do
    # 'supersede' shows up as a list, thus append via [last()+1].
    # Not idempotent, repeated options don't cause problems though.
    augtool -e -l "$config" set "/files${config}/supersede[last()+1]/${opt}" "\\\"$domain\\\""
  done
}

_resolv_set_domain() {
  local domain=$1
  local config="/etc/resolv.conf"

  for opt in domain search/domain; do
    augtool -e -l "$config" set "/files${config}/${opt}" "$domain"
  done
}

if [ -e $guard_file ]; then
  echo "Already provisioned: $(ls -la $guard_file)"
  exit 0
fi

preflight
install_wmf_repo
provision_puppet
setup_locale
setup_az

touch $guard_file
