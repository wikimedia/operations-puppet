class openstack::nova::common::ussuri::buster(
) {
    require ::openstack::serverpackages::ussuri::buster

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
