class openstack::nova::common::rocky::buster(
) {
    require ::openstack::serverpackages::rocky::buster

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
