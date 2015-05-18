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
    $pdns_db_password,
    $pdns_recursor,
    $recursor_ip_range
) {

    package { [ 'pdns-server',
                'pdns-backend-mysql',
                'pdns-backend-pipe' ]:
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

    # resolve_floating_domains.py is a hacked-together split-horizon
    #  implementation.  pdns uses the pipe_backend to delegate requests
    #  to resolve_floating_domains.py, which returns local IPs if it
    #  finds a match in the floating_domains file.
    file { '/etc/powerdns/resolve_floating_domains.py':
        ensure  => 'present',
        require => Package['pdns-server'],
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/labs_dns/resolve_floating_domains.py'
    }
    file { '/etc/powerdns/floating_domains':
        ensure  => 'present',
        require => Package['pdns-server'],
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/labs_dns/floating_domains'
    }


    service { 'pdns':
        ensure     => 'running',
        require    => [ Package['pdns-server'],
                        File['/etc/powerdns/pdns.conf']
        ],
        subscribe  => File['/etc/powerdns/pdns.conf', '/etc/powerdns/floating_domains', '/etc/powerdns/resolve_floating_domains.py'],
        hasrestart => false,
    }

    # Monitoring
    monitoring::host { $dns_auth_soa_name:
        ip_address => $dns_auth_ipaddress,
    }
    monitoring::service { 'labs auth dns (designate)':
        host          => $dns_auth_soa_name,
        description   => 'Auth DNS for labs pdns',
        check_command => 'check_dns!nagiostest.eqiad.wmflabs',
    }
}
