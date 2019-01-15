#!/usr/bin/env bash
# Script to decommission appservers once they're switched to role::spare::system
# This script will persist the switch of roles and should be used to avoid things
# to keep running once the system is moved to spares
set -e

# source the MediaWiki profile
. /etc/profile.d/mediawiki.sh

function stop_and_mask() {
  _service="$1";
  systemctl is-active --quiet "$_service" && systemctl stop "$_service" || echo "Service ${_service} not running";
  systemctl mask "$_service"
  echo "Stopped and masked ${_service}"
}

function is_installed() {
  if dpkg -s "$1" > /dev/null 2>&1;
  then
    return 0;
  else
    return 1;
  fi
}

# Let's make sure we're depooled from all pools
which decommission && decommission

# Let's first stop and mask the web servers
for service in apache2 nginx prometheus-apache-exporter prometheus-hhvm-exporter prometheus-nutcracker-exporter;
do
  stop_and_mask "${service}"
done

# Now let's check for nutcracker and hhvm/php-fpm
for service in nutcracker hhvm;
do
  is_installed "${service}" && stop_and_mask "${service}"
done

# Let's remove the MediaWiki source tree
test -d "${MEDIAWIKI_DEPLOYMENT_DIR}" && rm -rf "${MEDIAWIKI_DEPLOYMENT_DIR}"
# Let's also remove all references to conftool
for user in root mwdeploy;
do
  _file="~${user}/.etcdrc"
  test -f "${_file}" && rm "${_file}"
done

# Remove our own logrotate rules so they don't spam us
pushd /etc/logrotate.d
rm -f hhvm mediawiki_apache nginx nutcracker
popd

# Remove any trace of tmpreaper to avoid daily cronspam
apt-get purge tmpreaper