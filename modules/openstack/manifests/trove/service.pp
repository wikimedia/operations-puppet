class openstack::trove::service(
    String              $version,
    Array[Stdlib::Fqdn] $openstack_controllers,
    String              $db_user,
    String              $db_pass,
    String              $db_name,
    Stdlib::Fqdn        $db_host,
    String              $ldap_user_pass,
    String              $keystone_admin_uri,
    String              $region,
    Stdlib::Port        $api_bind_port,
    String              $rabbit_user,
    String              $rabbit_pass,
    String              $trove_guest_rabbit_user,
    String              $trove_guest_rabbit_pass,
) {
    class { "openstack::trove::service::${version}":
        openstack_controllers   => $openstack_controllers,
        db_user                 => $db_user,
        db_pass                 => $db_pass,
        db_name                 => $db_name,
        db_host                 => $db_host,
        ldap_user_pass          => $ldap_user_pass,
        keystone_admin_uri      => $keystone_admin_uri,
        region                  => $region,
        api_bind_port           => $api_bind_port,
        rabbit_user             => $rabbit_user,
        rabbit_pass             => $rabbit_pass,
        trove_guest_rabbit_user => $trove_guest_rabbit_user,
        trove_guest_rabbit_pass => $trove_guest_rabbit_pass,
    }

    service { 'trove-api':
        require => Package['trove-api'],
    }

    service { 'trove-taskmanager':
        require => Package['trove-taskmanager'],
    }

    service { 'trove-conductor':
        require => Package['trove-conductor'],
    }
}
