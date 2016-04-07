# Sets up a simple devpi server
class devpi {
    require_package('virtualenv')

    group { 'devpi':
        ensure => present,
        system => true,
    }

    user { 'devpi':
        ensure     => present,
        shell      => '/bin/false',
        home       => '/srv/devpi',
        managehome => true,
        system     => true,
    }

    file { '/srv/devpi':
        ensure => directory,
        owner  => 'devpi',
        group  => 'devpi',
        mode   => '0755'
    }

    git::clone { 'operations/wheels/devpi':
        directory => '/srv/devpi/venv',
        owner     => 'devpi',
        group     => 'devpi',
        mode      => '0770',
        require   => File['/srv/devpi'],
    }

    base::service_unit { 'devpi':
        systemd   => true,
        subscribe => Git::Clone['operations/wheels/devpi'],
    }

    nginx::site { 'devpi':
        source => 'puppet:///modules/devpi/nginx.conf',
    }
}
