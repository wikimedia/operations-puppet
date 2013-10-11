# Class: role::install-server
#
# A WMF role class used to install all the install-server stuff
#
# Parameters:
#
# Actions:
#       Install and configure all needed software to have an installation server
#       ready
#
# Requires:
#
#   Class['install-server::ubuntu-mirror']
#   Class['install-server::apt-repository']
#   Class['install-server::preseed-server']
#   Class['install-server::tftp-server']
#   Class['install-server::caching-proxy']
#   Class['install-server::web-server']
#   Class['install-server::dhcp-server']
#   Define['backup::set']
#   Class['ferm']
#   Define['ferm::rule']
#   Define['apt::pin']
#
# Sample Usage:
#       include role::install-server

class role::install-server {
    system::role { 'role::install-server':
        description => 'WMF Install server. APT repo, Forward Caching, TFTP, \
                        DHCP and Web server',
    }

    include ferm
    include backup::host
    include install-server::ubuntu-mirror
    include install-server::apt-repository
    include install-server::preseed-server
    include install-server::tftp-server
    include install-server::caching-proxy
    include install-server::web-server
    include install-server::dhcp-server

    # Backup
    $sets = [ 'srv-autoinstall',
              'srv-tftpboot',
              'srv-wikimedia',
            ]
    backup::set { $sets : }

    ferm::rule { 'tftp':
        rule => 'proto tcp dport tftp { saddr $ALL_NETWORKS ACCEPT; }'
    }

    # pin package to the default, Ubuntu version, instead of our own
    apt::pin { [ 'squid', 'squid-common', 'squid-langpack' ]:
        pin      => 'release o=Ubuntu',
        priority => '1001',
        before   => Package['squid'],
    }

    # Monitoring
    monitor_service { 'squid':
        description   => 'Squid',
        check_command => 'check_tcp!8080',
    }
    monitor_service { 'http':
        description   => 'HTTP',
        check_command => 'check_http',
    }
}
