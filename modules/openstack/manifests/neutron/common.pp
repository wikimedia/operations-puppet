class openstack::neutron::common(
    $version,
    Array[Stdlib::Fqdn] $memcached_nodes,
    Array[Stdlib::Fqdn] $rabbitmq_nodes,
    Stdlib::Fqdn $keystone_fqdn,
    $db_pass,
    $db_user,
    $db_host,
    $region,
    $dhcp_domain,
    $ldap_user_pass,
    $rabbit_user,
    $rabbit_pass,
    $log_agent_heartbeats,
    $agent_down_time,
    Stdlib::Port $bind_port,
    Boolean $enforce_policy_scope,
    Boolean $enforce_new_policy_defaults,
    ) {

    class { "openstack::neutron::common::${version}":
        memcached_nodes             => $memcached_nodes,
        rabbitmq_nodes              => $rabbitmq_nodes,
        keystone_fqdn               => $keystone_fqdn,
        db_pass                     => $db_pass,
        db_user                     => $db_user,
        db_host                     => $db_host,
        region                      => $region,
        dhcp_domain                 => $dhcp_domain,
        ldap_user_pass              => $ldap_user_pass,
        rabbit_user                 => $rabbit_user,
        rabbit_pass                 => $rabbit_pass,
        log_agent_heartbeats        => $log_agent_heartbeats,
        agent_down_time             => $agent_down_time,
        bind_port                   => $bind_port,
        enforce_policy_scope        => $enforce_policy_scope,
        enforce_new_policy_defaults => $enforce_new_policy_defaults,
    }

    file { '/etc/neutron/plugins/ml2':
        ensure  => directory,
        mode    => '0755',
        recurse => true,
        purge   => true,
        require => Package['neutron-common'],
    }
}
