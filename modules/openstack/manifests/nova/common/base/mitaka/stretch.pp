class openstack::nova::common::base::mitaka::stretch(
) {
    require ::openstack::serverpackages::mitaka::stretch

    $packages = [
        'unzip',
        'bridge-utils',
        'sqlite3',
        'python-mysqldb',
    ]

    package { $packages:
        ensure => 'present',
    }

    package { 'python-dogpile.core':
        ensure          => 'present',
        install_options => ['-t', 'jessie'],
    }

    package { 'python-nova':
        ensure          => 'present',
        install_options => ['-t', 'jessie-backports'],
        require         => Package['python-dogpile.core'],
    }

    package { 'nova-common':
        ensure          => 'present',
        install_options => ['-t', 'jessie-backports'],
        require         => [Package[$packages], Package['python-nova']],
    }
}
