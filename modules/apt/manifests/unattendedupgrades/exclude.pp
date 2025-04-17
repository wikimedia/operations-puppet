# SPDX-License-Identifier: Apache-2.0
# @summary excludes a specific package from unattended upgrades
define apt::unattendedupgrades::exclude (
  Wmflib::Ensure $ensure  = 'present',
  String[1]      $package = $title,
) {
  apt::conf { "unattended-upgrades-exclude-${title}":
    ensure   => $ensure,
    priority => 60,
    # Key with trailing '::' to append to potentially existing entry
    key      => 'Unattended-Upgrade::Package-Blacklist::',
    value    => "${package}^",
  }
}
