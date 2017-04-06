# Class: role::installserver::tftp
#
# A WMF role class used to install all the install_server TFTP stuff
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
#   Class['::base::firewall']
#   Define['ferm::rule']
#
# Sample Usage:
#       role(installserver::tftp)

class role::installserver::tftp {
    system::role { 'role::installserver::tftp':
        description => 'WMF TFTP server',
    }

    include ::standard
    include ::base::firewall
    include ::profile::backup::host
    include install_server::tftp_server

    ferm::rule { 'tftp':
        rule => 'proto udp dport tftp { saddr $PRODUCTION_NETWORKS ACCEPT; }'
    }

    backup::set { 'srv-tftpboot': }

}
