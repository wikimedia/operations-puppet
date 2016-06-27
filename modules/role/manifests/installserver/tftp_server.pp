# Class: role::install_server::tftp_server
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
#   Class['install-_server::tftp_server']
#   Class['base::firewall']
#   Define['ferm::rule']
#
# Sample Usage:
#       include role::installserver::tftp_server

class role::installserver::tftp_server {
    system::role { 'role::install_server::tftp_server':
        description => 'WMF TFTP server',
    }

    include base::firewall
    include install_server::tftp_server

    ferm::rule { 'tftp':
        rule => 'proto udp dport tftp { saddr $PRODUCTION_NETWORKS ACCEPT; }'
    }
}
