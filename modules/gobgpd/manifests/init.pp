# SPDX-License-Identifier: Apache-2.0
# == Class: gobgpd
#
# Install and manage gobgp: https://github.com/osrg/gobgp/
#
# === Parameters
#
#  [*config_content*]
#    GoBGP configuration to load
#    Default: undef
#

#
class gobgpd(
    String $config_content = undef,
) {
    ensure_packages(['gobgpd'])

    if $config_content {
        $process_ensure  = running
        $file_ensure = present
        $enabled = true
    } else {
        $process_ensure  = stopped
        $file_ensure = absent
        $enabled = false
    }
    file{ '/etc/gobgpd.conf':
        ensure  => $file_ensure,
        content => $config_content,
        # Don't automatically restart the daemon as the prefixes are in memory
        #notify  => Service['gobgpd'],
        require => Package['gobgpd'],
    }
    service {'gobgpd':
        ensure => $process_ensure,
        enable => $enabled,
    }

    # Routes are kept in memory, so a restart need to be properly planned between the two instances
    # profile::auto_restarts::service { 'gobgpd': }

}
