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

class profile::installserver::tftp {

    class { '::install_server::tftp_server': }

    ferm::rule { 'tftp':
        rule => 'proto udp dport tftp { saddr $PRODUCTION_NETWORKS ACCEPT; }'
    }

    backup::set { 'srv-tftpboot': }

    nrpe::monitor_service { 'atftpd':
        description  => 'TFTP service',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u nobody --ereg-argument-array=\'.*/usr/sbin/atftpd .*\'',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Monitoring/atftpd',
    }

}
