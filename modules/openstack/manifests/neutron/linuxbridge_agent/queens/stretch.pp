class openstack::neutron::linuxbridge_agent::queens::stretch(
) {
    require ::openstack::serverpackages::queens::stretch

    package { 'libosinfo-1.0-0':
        ensure => 'present',
    }

    package { 'neutron-linuxbridge-agent':
        ensure => 'present',
    }
}
