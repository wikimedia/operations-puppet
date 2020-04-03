class openstack::neutron::linuxbridge_agent::rocky::stretch(
) {
    require ::openstack::serverpackages::rocky::stretch

    package { 'libosinfo-1.0-0':
        ensure => 'present',
    }

    package { 'neutron-linuxbridge-agent':
        ensure => 'present',
    }
}
