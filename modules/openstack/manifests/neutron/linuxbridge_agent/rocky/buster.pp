class openstack::neutron::linuxbridge_agent::rocky::buster(
) {
    require ::openstack::serverpackages::rocky::buster

    package { 'libosinfo-1.0-0':
        ensure => 'present',
    }

    package { 'neutron-linuxbridge-agent':
        ensure => 'present',
    }
}
