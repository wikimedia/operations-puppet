class openstack::neutron::common(
    $version,
    $nova_controller,
    $nova_controller_standby,
    $keystone_host,
    $db_pass,
    $db_user,
    $db_host,
    $region,
    $ldap_user_pass,
    $rabbit_user,
    $rabbit_pass,
    $tld,
    $log_agent_heartbeats,
    $agent_down_time,
    ) {

    class { "openstack::neutron::common::${version}":
        nova_controller         => $nova_controller,
        nova_controller_standby => $nova_controller_standby,
        keystone_host           => $keystone_host,
        db_pass                 => $db_pass,
        db_user                 => $db_user,
        db_host                 => $db_host,
        region                  => $region,
        ldap_user_pass          => $ldap_user_pass,
        rabbit_user             => $rabbit_user,
        rabbit_pass             => $rabbit_pass,
        tld                     => $tld,
        log_agent_heartbeats    => $log_agent_heartbeats,
        agent_down_time         => $agent_down_time,
    }

    $invalid_files = [
        '/etc/neutron/plugins/ml2/ml2_conf_sriov.ini',
        '/etc/neutron/plugins/ml2/openvswitch_agent.ini',
        '/etc/neutron/plugins/ml2/sriov_agent.ini',
    ]

    file { $invalid_files:
        ensure => 'absent',
    }
}
