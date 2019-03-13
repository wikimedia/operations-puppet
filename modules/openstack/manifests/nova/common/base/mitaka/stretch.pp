class openstack::nova::common::base::mitaka::stretch(
) {
    require ::openstack::serverpackages::mitaka::stretch

    $packages = [
        'unzip',
        'bridge-utils',
        'python-mysqldb',
    ]

    package { $packages:
        ensure => 'present',
    }

    package { 'python-dogpile.core':
        ensure          => 'present',
        install_options => ['-t', 'jessie'],
    }

    # packages will be installed from openstack-mitaka-jessie component from
    # the jessie-wikimedia repo, since that has higher apt pinning by default
    package { 'python-nova':
        ensure  => 'present',
        require => Package['python-dogpile.core'],
    }

    package { 'nova-common':
        ensure  => 'present',
        require => [Package[$packages], Package['python-nova']],
    }
}
