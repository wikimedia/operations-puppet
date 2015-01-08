# Class: role::installserver
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
#   Class['base::firewall']
#   Define['ferm::rule']
#
# Sample Usage:
#       include role::installserver

class role::installserver {
    system::role { 'role::install-server':
        description => 'WMF Install server. APT repo, Forward Caching, TFTP, \
                        DHCP and Web server',
    }

    include base::firewall
    include role::backup::host
    include install-server::apt-repository
    include install-server::preseed-server

    include mirrors::ubuntu
    nrpe::monitor_service {'check_ubuntu_mirror':
        description  => 'Ubuntu mirror in sync with upstream',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_apt_mirror /srv/ubuntu',
    }

    include mirrors::debian
    nrpe::monitor_service {'check_debian_mirror':
        description  => 'Debian mirror in sync with upstream',
        nrpe_command => '/usr/local/lib/nagios/plugins/check_apt_mirror /srv/debian',
    }

    include install-server::tftp-server
    ferm::rule { 'tftp':
        rule => 'proto udp dport tftp { saddr $ALL_NETWORKS ACCEPT; }'
    }

    class { 'squid3':
        config_source => 'puppet:///files/caching-proxy/squid3-apt-proxy.conf',
    }
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

    # Backup
    $sets = [ 'srv-autoinstall',
              'srv-tftpboot',
              'srv-wikimedia',
            ]
    backup::set { $sets : }

    # Monitoring
    monitoring::service { 'squid':
        description   => 'Squid',
        check_command => 'check_tcp!8080',
    }
    monitoring::service { 'http':
        description   => 'HTTP',
        check_command => 'check_http',
    }
}

# Class: role::install-server::tftp-server
#
# A WMF role class used to install all the install-server TFTP stuff
#
# Parameters:
#
# Actions:
#       Install and configure all needed software to have an installation server
#       TFTP server ready
#
# Requires:
#
#   Class['install-server::tftp-server']
#   Class['base::firewall']
#   Define['ferm::rule']
#
# Sample Usage:
#       include role::installserver::tftp-server

class role::installserver::tftp-server {
    system::role { 'role::install-server::tftp-server':
        description => 'WMF TFTP server',
    }

    include base::firewall
    include install-server::tftp-server

    ferm::rule { 'tftp':
        rule => 'proto udp dport tftp { saddr $ALL_NETWORKS ACCEPT; }'
    }
}
