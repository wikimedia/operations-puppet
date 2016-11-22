# Class: role::installserver
#
# A WMF role class used to install all the install_server stuff
#
# Parameters:
#
# Actions:
#       Install and configure all needed software to have an installation server
#       ready
#
# Requires:
#
#   Class['install_server::preseed_server']
#   Class['install_server::web_server']
#   Define['backup::set']
#   Class['base::firewall']
#   Define['ferm::service']
#
# Sample Usage:
#       include role::installserver

class role::installserver {
    system::role { 'role::install_server':
        description => 'WMF Install server. APT repo, Forward Caching, TFTP, \
                        DHCP and Web server',
    }

    include standard
    include base::firewall
    include role::backup::host
    include install_server::preseed_server

    # Backup
    $sets = [ 'srv-autoinstall',
            ]
    backup::set { $sets : }

}
