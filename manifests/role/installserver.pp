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
#   Class['install_server::tftp_server']
#   Class['install_server::web_server']
#   Define['backup::set']
#   Class['base::firewall']
#   Define['ferm::rule']
#
# Sample Usage:
#       include role::installserver

class role::installserver {
    system::role { 'role::install_server':
        description => 'WMF Install server. APT repo, Forward Caching, TFTP, \
                        DHCP and Web server',
    }

    include base::firewall
    include role::backup::host
    include role::installserver::mirrors
    include install_server::preseed_server

    include mirrors::tails

    include install_server::tftp_server
    ferm::rule { 'tftp':
        rule => 'proto udp dport tftp { saddr $PRODUCTION_NETWORKS ACCEPT; }'
    }

    if os_version('ubuntu >= trusty') or os_version('debian >= jessie') {
        $config_content = template('caching-proxy/squid.conf.erb')
    } else {
        $config_content = template('squid3/precise_acls_conf.erb', 'caching-proxy/squid.conf.erb')
    }

    class { 'squid3':
        config_content => $config_content,
    }

    cron { 'squid-logrotate':
        ensure  => 'present',
        command => '/usr/sbin/squid3 -k rotate',
        user    => 'root',
        hour    => '17',
        minute  => '15',
    }

    ferm::rule { 'proxy':
        rule => 'proto tcp dport 8080 { saddr $PRODUCTION_NETWORKS ACCEPT; }'
    }

    include install_server::web_server
    ferm::service { 'http':
        proto => 'tcp',
        port  => 'http'
    }
    ferm::service { 'https':
        proto => 'tcp',
        port  => 'https'
    }

    # Backup
    $sets = [ 'srv-autoinstall',
              'srv-tftpboot',
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

