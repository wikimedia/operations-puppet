class openstack::nova::common::base::mitaka::stretch(
) {
    require ::openstack::serverpackages::mitaka::stretch

    $packages = [
        'unzip',
        'bridge-utils',
    ]

    package { $packages:
        ensure => 'present',
    }

    package { 'nova-common':
        ensure          => 'present',
        install_options => ['-t', 'jessie-backports'],
    }
}
