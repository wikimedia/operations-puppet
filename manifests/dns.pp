# dns.pp
#
# Parameters:
# - $dns_auth_ipaddress:IP address PowerDNS will bind to and send packets from
# - $dns_auth_soa_name:DNS SOA name of the server
# - $dns_auth_master:Which DNS server to use as "master" to fetch zones from

class dns::auth-server::ldap(
    $dns_auth_ipaddress,
    $dns_auth_soa_name,
    $dns_auth_query_address = '',
    $ldap_hosts,
    $ldap_base_dn,
    $ldap_user_dn,
    $ldap_user_pass
) {

    package { [ 'pdns-server',
                'pdns-backend-ldap' ]:
        ensure => 'latest',
    }

    system::role { 'dns::auth-server-ldap':
        description => 'Authoritative DNS server (LDAP)',
    }

    file { '/etc/powerdns/pdns.conf':
        ensure  => 'present',
        require => Package['pdns-server'],
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('powerdns/pdns-ldap.conf.erb'),
    }

    service { 'pdns':
        ensure     => 'running',
        require    => [ Package['pdns-server'],
                        File['/etc/powerdns/pdns.conf']
        ],
        subscribe  => File['/etc/powerdns/pdns.conf'],
        hasrestart => false,
    }

    # Monitoring
    monitor_host { $dns_auth_soa_name:
        ip_address => $dns_auth_ipaddress,
    }
    monitor_service { 'auth dns':
        host          => $dns_auth_soa_name,
        description   => 'Auth DNS',
        check_command => 'check_dns!nagiostest.beta.wmflabs.org',
    }

}

# Class: Dns::Recursor
# Parameters:
# - $listen_addresses:
#       Addresses the DNS recursor should listen on for queries
#       (default: [$::ipaddress])
# - $allow_from:
#       Prefixes from which to allow recursive DNS queries
class dns::recursor(
    $listen_addresses = [$::ipaddress],
    $allow_from       = []
) {
    package { 'pdns-recursor':
        ensure => 'latest',
    }

    system::role { 'dns::recursor':
        ensure      => 'absent',
        description => 'Recursive DNS server',
    }

    include network::constants

    file { '/etc/powerdns/recursor.conf':
        ensure  => 'present',
        require => Package['pdns-recursor'],
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('powerdns/recursor.conf.erb'),
    }

    service { 'pdns-recursor':
        ensure    => 'running',
        require   => [Package['pdns-recursor'],
                      File['/etc/powerdns/recursor.conf']
        ],
        subscribe => File['/etc/powerdns/recursor.conf'],
        pattern   => 'pdns_recursor',
        hasstatus => false,
    }

    class metrics {
        # install ganglia metrics reporting on pdns_recursor
        file { '/usr/local/sbin/pdns_gmetric':
            ensure => 'present',
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///files/powerdns/pdns_gmetric',
        }
        cron { 'pdns_gmetric_cron':
            require => File['/usr/local/sbin/pdns_gmetric'],
            command => '/usr/local/sbin/pdns_gmetric',
            user    => 'root',
            minute  => '*',
        }
    }

    define monitor() {
        # Monitoring
        monitor_host { $title:
            ip_address => $title,
        }
        monitor_service { "recursive dns ${title}":
            host          => $title,
            description   => 'Recursive DNS',
            check_command => 'check_dns!www.wikipedia.org',
        }
    }

    class statistics {
        package { 'rrdtool':
            ensure => 'latest',
        }

        file { '/usr/local/powerdnsstats':
            source  => 'puppet:///files/powerdns/recursorstats/scripts',
            recurse => remote,
        }

        file { '/var/www/pdns':
            source  => 'puppet:///files/powerdns/recursorstats/www',
            recurse => 'remote',
        }

        exec { '/usr/local/powerdnsstats/create':
            require => [Package['rrdtool'],
                        File['/usr/local/powerdnsstats']
            ],
            cwd     => '/var/www/pdns',
            user    => 'root',
            creates => '/var/www/pdns/pdns_recursor.rrd',
        }

        cron { 'pdnsstats':
            command => 'cd /var/www/pdns && /usr/local/powerdnsstats/update && /usr/local/powerdnsstats/makegraphs >/dev/null',
            user    => 'root',
            minute  => '*/5',
        }

        # Install a static web server to serve this
        include webserver::static
    }
    include metrics
}
