# == Class cergen
# Installs cergen package.
#
class cergen {

    if os_version('debian == buster') {
        package { 'cergen':
            ensure  => 'present',
            require => [
                        Exec['apt_update_cergen'],
                        Apt::Repository['buster-cergen'],
                        ],
        }

        apt::repository { 'buster-cergen':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => 'buster-wikimedia',
            components => 'component/cergen',
            notify     => Exec['apt_update_cergen'],
        }

        exec {'apt_update_cergen':
            command     => '/usr/bin/apt-get update',
            refreshonly => true,
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
