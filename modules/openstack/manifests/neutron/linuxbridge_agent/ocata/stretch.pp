class openstack::neutron::linuxbridge_agent::ocata::stretch(
) {
    require ::openstack::serverpackages::ocata::stretch

    package { 'libosinfo-1.0-0':
        ensure => 'present',
    }

    package { 'neutron-linuxbridge-agent':
        ensure => 'present',
    }
}
