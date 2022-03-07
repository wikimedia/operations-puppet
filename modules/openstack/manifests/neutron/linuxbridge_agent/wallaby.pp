class openstack::neutron::linuxbridge_agent::wallaby(
    $report_interval,
    $bridge_mappings={},
    $physical_interface_mappings={},
) {
    class { "openstack::neutron::linuxbridge_agent::wallaby::${::lsbdistcodename}": }

    file { '/etc/neutron/plugins/ml2/linuxbridge_agent.ini':
        owner   => 'root',
        group   => 'root',
        mode    => '0744',
        content => template('openstack/wallaby/neutron/plugins/ml2/linuxbridge_agent.ini.erb'),
        require => Package['neutron-linuxbridge-agent'],
    }
}
