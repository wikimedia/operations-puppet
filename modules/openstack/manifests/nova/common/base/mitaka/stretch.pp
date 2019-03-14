class openstack::nova::common::base::mitaka::stretch(
) {
    require ::openstack::serverpackages::mitaka::stretch

    $packages = [
        'unzip',
        'bridge-utils',
        'python-mysqldb',
        'nova-common',
    ]

    # packages will be installed from openstack-mitaka-jessie component from
    # the jessie-wikimedia repo, since that has higher apt pinning by default
    package { $packages:
        ensure => 'present',
    }
}
