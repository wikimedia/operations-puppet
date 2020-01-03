# == Class cergen
# Installs cergen package.
#
class cergen {

    if os_version('debian == buster') {
        apt::package_from_component { 'cergen':
            component => 'component/cergen',
            packages  => ['cergen']
        }

        # This is needed by networkx, ideally this would be fixed in
        # the cergen package itself
        package { 'python3-lib2to3':
            ensure => 'present',
        }
    } else {
        package { 'cergen':
            ensure => 'present',
        }
    }

    file { '/etc/cergen':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0750',
    }
}
