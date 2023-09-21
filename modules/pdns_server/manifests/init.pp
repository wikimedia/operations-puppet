# SPDX-License-Identifier: Apache-2.0
# @param $listen_on addresses to bind to for answering queries
# @param $dns_auth_query_address The IP address to use as a source address for sending queries.
#
# - $dns_auth_soa_name:DNS SOA name of the server
# - $pdns_db_host:Database server backing PDNS
# - $pdns_db_password:PDNS user database password

class pdns_server(
    Array[Stdlib::IP::Address] $listen_on,
    Stdlib::Fqdn               $default_soa_content,
    Stdlib::Fqdn               $query_local_address,
    $pdns_db_host,
    $pdns_db_password,
    $dns_webserver = false,
    $dns_webserver_address = $::ipaddress,
    $dns_api_key = '',
    $dns_api_allow_from = [],
) {

    package { [ 'pdns-server',
                'pdns-backend-mysql' ]:
        ensure => 'present',
    }

    file { '/etc/powerdns/pdns.conf':
        ensure  => 'present',
        owner   => 'root',
        group   => 'pdns',
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
