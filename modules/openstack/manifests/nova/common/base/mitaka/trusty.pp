class openstack::nova::common::base::mitaka::trusty(
) {
    require ::openstack::serverpackages::mitaka::trusty

    $packages = [
        'unzip',
        'bridge-utils',
        'nova-common',
    ]

    package { $packages:
        ensure => 'present',
    }
}
