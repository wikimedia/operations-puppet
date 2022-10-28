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
#   Class['::profile::base::firewall']
#   Define['ferm::rule']
#
# Sample Usage:
#       include ::profile::installserver::tftp

class profile::installserver::tftp (
    Enum['stopped', 'running'] $ensure_service = lookup('profile::installserver::tftp::ensure_service'),
){

    ensure_packages('tftp')

    class { '::install_server::tftp_server':
        ensure_service => $ensure_service,
    }

    ferm::service { 'tftp':
        proto  => 'udp',
        port   => 'tftp',
        srange => '$PRODUCTION_NETWORKS',
    }

    backup::set { 'srv-tftpboot': }

    $ensure_monitor = $ensure_service ? {
        'stopped' => 'absent',
        default   => 'present',
    }

    nrpe::monitor_service { 'atftpd':
        ensure       => $ensure_monitor,
        description  => 'TFTP service',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u nobody --ereg-argument-array=\'.*/usr/sbin/atftpd .*\'',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Monitoring/atftpd',
    }
}
