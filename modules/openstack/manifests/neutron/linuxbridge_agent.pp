class openstack::neutron::linuxbridge_agent(
    $version,
    $report_interval,
    $bridges={},
    $bridge_mappings={},
    $physical_interface_mappings={},
    ) {

    class { "openstack::neutron::linuxbridge_agent::${version}":
        report_interval             => $report_interval,
        physical_interface_mappings => $physical_interface_mappings,
        bridge_mappings             => $bridge_mappings,
    }

    include openstack::nova::compute::kmod
    create_resources(openstack::neutron::bridge, $bridges)

    file { '/etc/neutron/plugins/linuxbridge':
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0744',
        require => File['/etc/neutron/plugins/ml2/linuxbridge_agent.ini'],
    }

    file { '/etc/neutron/plugins/linuxbridge/linuxbridge_conf.ini':
        ensure  => 'link',
        target  => '/etc/neutron/plugins/ml2/linuxbridge_agent.ini',
        require => File['/etc/neutron/plugins/linuxbridge'],
    }

    service {'neutron-linuxbridge-agent':
        ensure    => 'running',
        require   => Package['neutron-linuxbridge-agent'],
        subscribe => [
                      File['/etc/neutron/neutron.conf'],
                      File['/etc/neutron/plugins/ml2/ml2_conf.ini'],
            ],
    }
}
