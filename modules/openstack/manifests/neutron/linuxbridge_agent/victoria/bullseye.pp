class openstack::neutron::linuxbridge_agent::victoria::bullseye(
) {
    require ::openstack::serverpackages::victoria::bullseye

    package { 'libosinfo-1.0-0':
        ensure => 'present',
    }

    package { 'neutron-linuxbridge-agent':
        ensure => 'present',
    }
}
