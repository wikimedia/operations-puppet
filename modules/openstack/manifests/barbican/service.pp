class openstack::barbican::service(
    String $version,
    String $db_user,
    String $db_pass,
    String $db_name,
    Stdlib::Fqdn $db_host,
    String $ldap_user_pass,
    String $crypto_kek,
    String $keystone_admin_uri,
    String $keystone_public_uri,
    Stdlib::Port $bind_port,
) {
    class { 'openstack::barbican::service::rocky':
        db_user             => $db_user,
        db_pass             => $db_pass,
        db_name             => $db_name,
        db_host             => $db_host,
        crypto_kek          => $crypto_kek,
        ldap_user_pass      => $ldap_user_pass,
        keystone_admin_uri  => $keystone_admin_uri,
        keystone_public_uri => $keystone_public_uri,
        bind_port           => $bind_port,
    }

    service { 'barbican-api':
        require => Package['barbican-api'],
    }
}
