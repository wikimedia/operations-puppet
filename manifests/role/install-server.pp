# Class: role::installserver
#
# A role class used to install all the install-server stuff
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
#   Class['base::firewall']
#   Define['ferm::rule']
#   Define['apt::pin']
#
# Sample Usage:
#       include role::installserver

class role::installserver {
    system::role { 'role::install-server':
        description => 'Install server. APT repo, Forward Caching, TFTP, \
                        DHCP and Web server',
    }

    include base::firewall
    include backup::host
    include install-server::apt-repository
    include install-server::preseed-server

    include install-server::ubuntu-mirror
    nrpe::monitor_service {'check_apt_mirror':
        description  => 'Ubuntu mirror in sync with upstream',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_apt_mirror'
    }

    include install-server::tftp-server
    ferm::rule { 'tftp':
        rule => 'proto udp dport tftp { saddr $ALL_NETWORKS ACCEPT; }'
    }

    include install-server::caching-proxy
    ferm::rule { 'proxy':
        rule => 'proto tcp dport 8080 { saddr $ALL_NETWORKS ACCEPT; }'
    }

    include install-server::web-server
    ferm::service { 'http':
        proto => 'tcp',
        port  => 'http'
    }

    include install-server::dhcp-server
    ferm::rule { 'dhcp':
        rule => 'proto udp dport bootps { saddr $ALL_NETWORKS ACCEPT; }'
    }

    # System user and group for mirroring
    generic::systemuser { 'mirror':
        name => 'mirror',
        home => '/var/lib/mirror',
        before => Class['install-server::ubuntu-mirror'],
    }

    # Backup
    $sets = [ 'srv-autoinstall',
              'srv-tftpboot',
              'srv-wikimedia',
            ]
    backup::set { $sets : }

    # FIXME: temporary, until url-downloader gets migrated to Squid 3.x (RT #7284)
    # and thus we can remove our custom squid 2.x package.
    # pin package to the default, Ubuntu version, instead of our own
    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '12.04') >= 0 {
        $pinned_packages = [
                            'squid3',
                            'squid-common3',
                            'squid-langpack',
                        ]
        $before_package = 'squid3'
    } else {
        $pinned_packages = [
                            'squid',
                            'squid-common',
                            'squid-langpack',
                        ]
        $before_package = 'squid'
    }
    apt::pin { $pinned_packages:
        pin      => 'release o=Ubuntu',
        priority => '1001',
        before   => Package[$before_package],
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

# Class: role::install-server::secondary
#
# A role class used to install a secondary install-server, used for example at
# caching PoPs. Includes a TFTP server and a forward caching proxy.
#
# Parameters:
#
# Actions:
#       Install and configure all needed software to have a secondary
#       installation server ready
#
# Requires:
#
#   Class['install-server::tftp-server']
#   Class['install-server::caching-proxy']
#   Class['base::firewall']
#   Define['ferm::rule']
#
# Sample Usage:
#       include role::installserver::secondary

class role::installserver::secondary {
    system::role { 'role::install-server::secondary':
        description => 'Secondary install server (TFTP, Caching proxy)',
    }

    include base::firewall
    include install-server::tftp-server

    ferm::rule { 'tftp':
        rule => 'proto udp dport tftp { saddr $ALL_NETWORKS ACCEPT; }'
    }

    include install-server::caching-proxy
    ferm::rule { 'proxy':
        rule => 'proto tcp dport 8080 { saddr $ALL_NETWORKS ACCEPT; }'
    }

    # Monitoring
    monitor_service { 'squid':
        description   => 'Squid',
        check_command => 'check_tcp!8080',
    }

    # FIXME: not DRY at all but temporary, see above
    # pin package to the default, Ubuntu version, instead of our own
    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '12.04') >= 0 {
        $pinned_packages = [
                            'squid3',
                            'squid-common3',
                            'squid-langpack',
                        ]
        $before_package = 'squid3'
    } else {
        $pinned_packages = [
                            'squid',
                            'squid-common',
                            'squid-langpack',
                        ]
        $before_package = 'squid'
    }
    apt::pin { $pinned_packages:
        pin      => 'release o=Ubuntu',
        priority => '1001',
        before   => Package[$before_package],
    }
}
