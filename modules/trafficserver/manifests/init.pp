# SPDX-License-Identifier: Apache-2.0
# == Class: trafficserver
# this class handles common stuff for every trafficserver instance
# === Parameters
#
# [*user*]
#   Run trafficserver as this user (default: 'trafficserver').
#
# [*packages*]
#   Array of required packages to run trafficserver (default: ['trafficserver', 'trafficserver-experimental-plugins']).
#
# [*install_ats9*]
#   Whether to install ATS 9.x from component. default: false.

class trafficserver(
  String        $user         = 'trafficserver',
  Array[String] $packages     = ['trafficserver', 'trafficserver-experimental-plugins'],
  Boolean       $install_ats9 = false,
) {
    # Mask trafficserver.service if the package is not installed yet. The
    # unless is deplorable but there is no way in Puppet to execute a command
    # only if a package is being installed but before package installation.
    systemd::mask { 'trafficserver.service':
        unless => '/usr/bin/dpkg -s trafficserver | /bin/grep -q "^Status: install ok installed$"',
    }

    if $install_ats9 {
      apt::package_from_component { $packages:
          component       => 'component/trafficserver9',
          ensure_packages => false,
      }
    }

    ## Packages
    package { $packages:
        ensure  => present,
        require => [ Exec['apt-get update'], Systemd::Mask['trafficserver.service'] ],
    }

    # Script used to depool, restart and pool an ATS instance
    file { '/usr/local/sbin/ats-restart':
        ensure => present,
        source => 'puppet:///modules/trafficserver/ats_restart.sh',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    rsyslog::conf { 'trafficserver':
        content  => file('trafficserver/rsyslog.conf'),
        priority => 20,
    }
}
