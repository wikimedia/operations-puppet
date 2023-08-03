# SPDX-License-Identifier: Apache-2.0
# Class: profile::installserver::tftp
#
# A WMF profile class used to install all the install_server TFTP stuff
#
# Parameters:
#
# Actions:
#       Install and configure all needed software to have an installation server
#       TFTP server ready
#
# Requires:
#
#   Class['install_server::tftp_server']
#   Class['::profile::firewall']
#   Define['ferm::rule']
#
# Sample Usage:
#       include ::profile::installserver::tftp

class profile::installserver::tftp (
    String $ztp_juniper_root_password = lookup('profile::installserver::tftp::ztp_juniper_root_password'),
) {

    ensure_packages('tftp')

    class { 'install_server::tftp_server':
      ztp_juniper_root_password => $ztp_juniper_root_password,
    }

    ferm::service { 'tftp':
        proto  => 'udp',
        port   => 69,
        srange => '($PRODUCTION_NETWORKS $MGMT_NETWORKS)',
    }

    backup::set { 'srv-tftpboot': }

    nrpe::monitor_service { 'atftpd':
        description  => 'TFTP service',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u nobody --ereg-argument-array=\'.*/usr/sbin/atftpd .*\'',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Monitoring/atftpd',
    }
}
