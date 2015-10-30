# == Class devpi
#
# PyPI proxy/cache. Meant to run on wmf labs
#
# http://doc.devpi.net/
#
class devpi {

    requires_realm('labs')
    require_package('python-pip')

    package { 'devpi-server':
        ensure   => '2.3.1',
        provider => 'pip',
        require  => Package['python-pip'],
    }

    user { 'devpi':
        home        => '/var/lib/devpi',
        managedhome => true,
        system      => true,
        gid         => 'devpi',
        require     => Group['devpi'],
    }

    group { 'devpi':
        ensure => present,
        name   => 'devpi',
        system => true,
    }

    file { '/srv/devpi':
        ensure => directory,
        mode   => '0775',
        owner  => 'devpi',
        group  => 'devpi',
    }

    base::service_unit { 'devpi':
        ensure         => present,
        refresh        => true,
        systemd        => true,
        service_params => {},
        require        => [
            File['/srv/devpi'],
            Package['devpi-server'],
        ],
    }

}
