class openstack::trove::service(
    String              $version,
    Integer             $workers,
    Array[Stdlib::Fqdn] $memcached_nodes,
    Array[Stdlib::Fqdn] $rabbitmq_nodes,
    String              $db_user,
    String              $db_pass,
    String              $db_name,
    Stdlib::Fqdn        $db_host,
    String              $ldap_user_pass,
    Stdlib::Fqdn        $keystone_fqdn,
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
    Boolean             $enforce_policy_scope,
    Boolean             $enforce_new_policy_defaults,
    String              $trove_service_project = 'trove',
    String              $trove_service_user = 'trove',
    String              $trove_quay_user = 'wikimedia-cloud-services+troveguest',
) {
    class { "openstack::trove::service::${version}":
        memcached_nodes             => $memcached_nodes,
        rabbitmq_nodes              => $rabbitmq_nodes,
        workers                     => $workers,
        db_user                     => $db_user,
        db_pass                     => $db_pass,
        db_name                     => $db_name,
        db_host                     => $db_host,
        ldap_user_pass              => $ldap_user_pass,
        keystone_fqdn               => $keystone_fqdn,
        region                      => $region,
        api_bind_port               => $api_bind_port,
        rabbit_user                 => $rabbit_user,
        rabbit_pass                 => $rabbit_pass,
        trove_guest_rabbit_user     => $trove_guest_rabbit_user,
        trove_guest_rabbit_pass     => $trove_guest_rabbit_pass,
        trove_service_user_pass     => $trove_service_user_pass,
        trove_service_project       => $trove_service_project,
        trove_service_user          => $trove_service_user,
        trove_quay_user             => $trove_quay_user,
        trove_quay_pass             => $trove_quay_pass,
        designate_internal_uri      => $designate_internal_uri,
        trove_dns_zone              => $trove_dns_zone,
        trove_dns_zone_id           => $trove_dns_zone_id,
        enforce_policy_scope        => $enforce_policy_scope,
        enforce_new_policy_defaults => $enforce_new_policy_defaults,
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
