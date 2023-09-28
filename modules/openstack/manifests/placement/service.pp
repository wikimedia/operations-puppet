class openstack::placement::service(
    Array[Stdlib::Fqdn] $memcached_nodes,
    $version,
    $db_user,
    $db_pass,
    $db_name,
    $db_host,
    $ldap_user_pass,
    $keystone_fqdn,
    Stdlib::Port $api_bind_port,
) {
    class { "openstack::placement::service::${version}":
        memcached_nodes => $memcached_nodes,
        db_user         => $db_user,
        db_pass         => $db_pass,
        db_name         => $db_name,
        db_host         => $db_host,
        ldap_user_pass  => $ldap_user_pass,
        keystone_fqdn   => $keystone_fqdn,
        api_bind_port   => $api_bind_port,
    }

    service { 'placement-api':
        ensure  => running,
        require => Package['placement-api'],
    }

    rsyslog::conf { 'placement':
        source   => 'puppet:///modules/openstack/placement/placement.rsyslog.conf',
        priority => 20,
    }
}
