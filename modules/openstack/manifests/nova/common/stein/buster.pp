class openstack::nova::common::stein::buster(
) {
    require ::openstack::serverpackages::stein::buster

    $packages = [
        'unzip',
        'bridge-utils',
        'python-mysqldb',
        'nova-common',
    ]

    package { $packages:
        ensure => 'present',
    }
}
