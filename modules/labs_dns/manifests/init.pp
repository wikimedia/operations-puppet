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
    $pdns_db_password
) {

    package { [ 'pdns-server',
                'pdns-backend-mysql' ]:
        ensure => 'present',
    }

    file { '/etc/powerdns/pdns.conf':
        ensure  => 'present',
        require => Package['pdns-server'],
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('labs_dns/pdns.conf.erb'),
    }

    # Clean up any example configs that the pdns packages might have installed;
    #  We don't want them accidentally used or merged into our puppetized config.
    file { '/etc/powerdns/pdns.d/':
        ensure        => directory,
        purge         => true,
        recurse       => true,
    }

    service { 'pdns':
        ensure     => 'running',
        require    => [ Package['pdns-server'],
                        File['/etc/powerdns/pdns.conf']
        ],
        subscribe  => File['/etc/powerdns/pdns.conf'],
        hasrestart => false,
    }
}
