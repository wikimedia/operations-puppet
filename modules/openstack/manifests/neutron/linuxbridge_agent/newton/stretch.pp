class openstack::neutron::linuxbridge_agent::newton::stretch(
) {
    require ::openstack::serverpackages::newton::stretch

    package { 'libosinfo-1.0-0':
        ensure => 'present',
    }

    package { 'neutron-linuxbridge-agent':
        ensure => 'present',
    }
}
