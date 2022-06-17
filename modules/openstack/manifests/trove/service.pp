class openstack::trove::service(
    String              $version,
    Integer             $workers,
    Array[Stdlib::Fqdn] $openstack_controllers,
    String              $db_user,
    String              $db_pass,
    String              $db_name,
    Stdlib::Fqdn        $db_host,
    String              $ldap_user_pass,
    String              $keystone_admin_uri,
    String              $keystone_internal_uri,
    String              $region,
    Stdlib::Port        $api_bind_port,
    String              $rabbit_user,
    String              $rabbit_pass,
    String              $trove_guest_rabbit_user,
    String              $trove_guest_rabbit_pass,
    String              $trove_service_user_pass,
    String              $trove_quay_pass,
    String              $designate_internal_uri,
    String              $trove_dns_zone,
    String              $trove_dns_zone_id,
    String              $trove_service_project = 'trove',
    String              $trove_service_user = 'trove',
    String              $trove_quay_user = 'wikimedia-cloud-services+troveguest',
) {
    class { "openstack::trove::service::${version}":
        openstack_controllers   => $openstack_controllers,
        workers                 => $workers,
        db_user                 => $db_user,
        db_pass                 => $db_pass,
        db_name                 => $db_name,
        db_host                 => $db_host,
        ldap_user_pass          => $ldap_user_pass,
        keystone_admin_uri      => $keystone_admin_uri,
        keystone_internal_uri   => $keystone_internal_uri,
        region                  => $region,
        api_bind_port           => $api_bind_port,
        rabbit_user             => $rabbit_user,
        rabbit_pass             => $rabbit_pass,
        trove_guest_rabbit_user => $trove_guest_rabbit_user,
        trove_guest_rabbit_pass => $trove_guest_rabbit_pass,
        trove_service_user_pass => $trove_service_user_pass,
        trove_service_project   => $trove_service_project,
        trove_service_user      => $trove_service_user,
        trove_quay_user         => $trove_quay_user,
        trove_quay_pass         => $trove_quay_pass,
        designate_internal_uri  => $designate_internal_uri,
        trove_dns_zone          => $trove_dns_zone,
        trove_dns_zone_id       => $trove_dns_zone_id,
    }

    service { 'trove-api':
        ensure  => running,
        require => Package['trove-api'],
    }

    service { 'trove-taskmanager':
        ensure  => running,
        require => Package['trove-taskmanager'],
    }

    service { 'trove-conductor':
        ensure  => running,
        require => Package['trove-conductor'],
    }
}
