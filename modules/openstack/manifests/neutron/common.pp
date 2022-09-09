class openstack::neutron::common(
    $version,
    Array[Stdlib::Fqdn] $openstack_controllers,
    Array[Stdlib::Fqdn] $rabbitmq_nodes,
    Stdlib::Fqdn $keystone_api_fqdn,
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
    Stdlib::HTTPUrl $keystone_admin_uri,
    Stdlib::HTTPUrl $keystone_public_uri,
    ) {

    class { "openstack::neutron::common::${version}":
        openstack_controllers => $openstack_controllers,
        rabbitmq_nodes        => $rabbitmq_nodes,
        keystone_admin_uri    => $keystone_admin_uri,
        keystone_api_fqdn     => $keystone_api_fqdn,
        keystone_public_uri   => $keystone_public_uri,
        db_pass               => $db_pass,
        db_user               => $db_user,
        db_host               => $db_host,
        region                => $region,
        dhcp_domain           => $dhcp_domain,
        ldap_user_pass        => $ldap_user_pass,
        rabbit_user           => $rabbit_user,
        rabbit_pass           => $rabbit_pass,
        log_agent_heartbeats  => $log_agent_heartbeats,
        agent_down_time       => $agent_down_time,
        bind_port             => $bind_port,
    }

    # Installed by neutron-common
    $invalid_files = [
        '/etc/neutron/plugins/ml2/ml2_conf_sriov.ini',
        '/etc/neutron/plugins/ml2/openvswitch_agent.ini',
        '/etc/neutron/plugins/ml2/sriov_agent.ini',
    ]

    file { $invalid_files:
        ensure => 'absent',
    }
}
