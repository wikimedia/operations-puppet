class openstack::neutron::common::mitaka(
    $nova_controller,
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

    class { "openstack::neutron::common::mitaka::${::lsbdistcodename}": }

    file { '/etc/neutron/neutron.conf':
            owner   => 'neutron',
            group   => 'neutron',
            mode    => '0660',
            content => template('openstack/mitaka/neutron/neutron.conf.erb'),
            require => Package['neutron-common'];
    }

    file { '/etc/neutron/policy.json':
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/openstack/mitaka/neutron/policy.json',
            require => Package['neutron-common'];
    }

    file { '/etc/neutron/plugins/ml2/ml2_conf.ini':
        owner   => 'neutron',
        group   => 'neutron',
        mode    => '0744',
        content => template('openstack/mitaka/neutron/plugins/ml2/ml2_conf.ini.erb'),
        require => Package['neutron-common'];
    }
}
