class openstack::nova::common::base::mitaka::jessie(
) {
    require ::openstack::serverpackages::mitaka::jessie

    $packages = [
        'unzip',
        'bridge-utils',
        'nova-common',
    ]

    package { $packages:
        ensure          => 'present',
        install_options => ['-t', 'jessie-backports'],
    }

    file {'/etc/nova/original':
        ensure  => 'directory',
        owner   => 'nova',
        group   => 'nova',
        mode    => '0755',
        recurse => true,
        source  => 'puppet:///modules/openstack/mitaka/nova/original',
        require => Package['nova-common'],
    }
}
