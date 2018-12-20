class openstack::neutron::common(
    $version,
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

    class { "openstack::neutron::common::${version}::${::lsbdistcodename}": }

    file { '/etc/neutron/neutron.conf':
            owner   => 'neutron',
            group   => 'neutron',
            mode    => '0660',
            content => template("openstack/${version}/neutron/neutron.conf.erb"),
            require => Package['neutron-common'];
    }

    file { '/etc/neutron/policy.json':
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            source  => 'puppet:///modules/openstack/mitaka/neutron/policy.json',
            require => Package['neutron-common'];
    }

    $invalid_files = [
        '/etc/neutron/plugins/ml2/ml2_conf_sriov.ini',
        '/etc/neutron/plugins/ml2/openvswitch_agent.ini',
        '/etc/neutron/plugins/ml2/sriov_agent.ini',
    ]

    file { $invalid_files:
        ensure => 'absent',
    }

    file { '/etc/neutron/plugins/ml2/ml2_conf.ini':
        owner   => 'neutron',
        group   => 'neutron',
        mode    => '0744',
        content => template("openstack/${version}/neutron/plugins/ml2/ml2_conf.ini.erb"),
        require => Package['neutron-common'];
    }

    if os_version('debian == jessie') {

        file {'/etc/neutron/original':
            ensure  => 'directory',
            owner   => 'neutron',
            group   => 'neutron',
            mode    => '0755',
            recurse => true,
            source  => "puppet:///modules/openstack/${version}/neutron/original",
        }
    }
}
