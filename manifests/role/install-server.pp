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
#   Class['misc::install-server::ubuntu-mirror']
#   Class['misc::install-server::apt-repository']
#   Class['misc::install-server::preseed-server']
#   Class['misc::install-server::tftp-server']
#   Class['misc::install-server::caching-proxy']
#   Class['misc::install-server::web-server']
#   Class['misc::install-server::dhcp-server']
#   Define['backup::set']
#
# Sample Usage:
#       include role::install-server

class role::install-server {
    system_role { 'role::install-server':
        description => 'WMF Install server. APT repo, Forward Caching, TFTP, \
                        DHCP and Web server',
    }

    include misc::install-server::ubuntu-mirror,
        misc::install-server::apt-repository,
        misc::install-server::preseed-server,
        misc::install-server::tftp-server,
        misc::install-server::caching-proxy,
        misc::install-server::web-server,
        misc::install-server::dhcp-server

    # Backup
        $sets = [ 'srv-autoinstall',
                  'srv-tftpboot',
                  'srv-wikimedia',
                ]
        include backup::host
        backup::set { $sets : }

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
