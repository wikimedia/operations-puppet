class openstack::neutron::linuxbridge_agent::pike::stretch(
) {
    require ::openstack::serverpackages::pike::stretch

    package { 'libosinfo-1.0-0':
        ensure => 'present',
    }

    package { 'neutron-linuxbridge-agent':
        ensure => 'present',
    }
}
