class openstack::barbican::service(
    Array[Stdlib::Fqdn] $memcached_nodes,
    String $version,
    String $db_user,
    String $db_pass,
    String $db_name,
    Stdlib::Fqdn $db_host,
    String $ldap_user_pass,
    String $crypto_kek,
    String $keystone_fqdn,
    Stdlib::Port $bind_port,
) {
    class { "openstack::barbican::service::${version}":
        memcached_nodes => $memcached_nodes,
        db_user         => $db_user,
        db_pass         => $db_pass,
        db_name         => $db_name,
        db_host         => $db_host,
        crypto_kek      => $crypto_kek,
        ldap_user_pass  => $ldap_user_pass,
        keystone_fqdn   => $keystone_fqdn,
        bind_port       => $bind_port,
    }

    service { 'barbican-api':
        ensure  => running,
        require => Package['barbican-api'],
    }
}
