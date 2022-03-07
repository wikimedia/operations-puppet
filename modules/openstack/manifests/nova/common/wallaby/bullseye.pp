class openstack::nova::common::wallaby::bullseye(
) {
    require ::openstack::serverpackages::wallaby::bullseye

    $packages = [
        'unzip',
        'bridge-utils',
        'nova-common',
    ]

    package { $packages:
        ensure => 'present',
    }
}
