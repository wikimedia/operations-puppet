class openstack::neutron::common::queens(
    $nova_controller,
    $nova_controller_standby,
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

    class { "openstack::neutron::common::queens::${::lsbdistcodename}": }

    $controller_hosts = [$nova_controller, $nova_controller_standby]
    file { '/etc/neutron/neutron.conf':
            owner     => 'neutron',
            group     => 'neutron',
            mode      => '0660',
            show_diff => false,
            content   => template('openstack/queens/neutron/neutron.conf.erb'),
            require   => Package['neutron-common'];
    }

    file { '/etc/neutron/policy.json':
        ensure => absent,
    }

    file { '/etc/neutron/policy.yaml':
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/openstack/queens/neutron/policy.yaml',
            require => Package['neutron-common'];
    }

    file { '/etc/neutron/plugins/ml2/ml2_conf.ini':
        owner   => 'neutron',
        group   => 'neutron',
        mode    => '0744',
        content => template('openstack/queens/neutron/plugins/ml2/ml2_conf.ini.erb'),
        require => Package['neutron-common'];
    }
}
