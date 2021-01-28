class openstack::placement::service(
    $openstack_controllers,
    $version,
    $db_user,
    $db_pass,
    $db_name,
    $db_host,
    $ldap_user_pass,
    $keystone_admin_uri,
    $keystone_public_uri,
    Stdlib::Port $api_bind_port,
) {
    class { "openstack::placement::service::${version}":
        openstack_controllers => $openstack_controllers,
        db_user               => $db_user,
        db_pass               => $db_pass,
        db_name               => $db_name,
        db_host               => $db_host,
        ldap_user_pass        => $ldap_user_pass,
        keystone_admin_uri    => $keystone_admin_uri,
        keystone_public_uri   => $keystone_public_uri,
        api_bind_port         => $api_bind_port,
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
