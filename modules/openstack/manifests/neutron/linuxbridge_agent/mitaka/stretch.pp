class openstack::neutron::linuxbridge_agent::mitaka::stretch(
) {
    require ::openstack::serverpackages::mitaka::stretch

    package { 'libosinfo-1.0-0':
        ensure => 'present',
    }

    package { 'neutron-linuxbridge-agent':
        ensure          => 'present',
        install_options => ['-t', 'jessie-backports'],
    }
}
