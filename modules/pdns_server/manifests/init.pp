# pdns_server/init.pp
#
# Parameters:
# - $dns_auth_ipaddress:IPv4 address PowerDNS will bind to and send packets from
# - $dns_auth_ipaddress6:IPv6 address PowerDNS will bind to and send packets from
# - $dns_auth_soa_name:DNS SOA name of the server
# - $pdns_db_host:Database server backing PDNS
# - $pdns_db_password:PDNS user database password
# - $dns_auth_query_address: The IP address to use as a source address for sending queries.

class pdns_server(
    $dns_auth_ipaddress,
    $dns_auth_ipaddress6,
    $dns_auth_soa_name,
    $pdns_db_host,
    $pdns_db_password,
    $dns_auth_query_address = ''
) {

    package { [ 'pdns-server',
                'pdns-backend-mysql' ]:
        ensure => 'present',
    }

    file { '/etc/powerdns/pdns.conf':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0440',
        content => template('pdns_server/pdns.conf.erb'),
        require => Package['pdns-server'],
    }

    # Clean up any example configs that the pdns packages might have installed;
    #  We don't want them accidentally used or merged into our puppetized config.
    file { '/etc/powerdns/pdns.d/':
        ensure  => 'directory',
        purge   => true,
        recurse => true,
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
