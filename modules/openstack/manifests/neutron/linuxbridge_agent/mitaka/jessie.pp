class openstack::neutron::linuxbridge_agent::mitaka::jessie(
) {
    require ::openstack::serverpackages::mitaka::jessie

    $packages = [
        'neutron-linuxbridge-agent',
        'libosinfo-1.0-0',
    ]

    package { $packages:
        ensure => 'present',
    }
}
