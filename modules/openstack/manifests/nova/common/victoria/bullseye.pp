class openstack::nova::common::victoria::bullseye(
) {
    require ::openstack::serverpackages::victoria::bullseye

    $packages = [
        'unzip',
        'bridge-utils',
        'nova-common',
    ]

    package { $packages:
        ensure => 'present',
    }
}
