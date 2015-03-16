# dns.pp
#
# Parameters:
# - $dns_auth_ipaddress:IP address PowerDNS will bind to and send packets from
# - $dns_auth_soa_name:DNS SOA name of the server
# - $dns_auth_master:Which DNS server to use as "master" to fetch zones from

class labs_dns(
    $dns_auth_ipaddress,
    $dns_auth_soa_name,
    $dns_auth_query_address = '',
    $pdns_db_host,
    $pdns_db_passwd
) {

    package { [ 'pdns-server',
                'pdns-backend-mysql' ]:
        ensure => 'present',
    }

    system::role { 'labs_dns':
        description => 'Authoritative DNS server (pdns/mysql)',
    }

    file { '/etc/powerdns/pdns.conf':
        ensure  => 'present',
        require => Package['pdns-server'],
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('labs_dns/pdns.conf.erb'),
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
    monitoring::host { $dns_auth_soa_name:
        ip_address => $dns_auth_ipaddress,
    }
    monitoring::service { 'labs auth dns':
        host          => $dns_auth_soa_name,
        description   => 'Auth DNS',
        check_command => 'check_dns!nagiostest.beta.wmflabs.org',
    }
}
