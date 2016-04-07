# Sets up a simple devpi server
class devpi {
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
    
    git::clone { 'operations/wheels/devpi':
        ensure    => latest,
        directory => '/srv/devpi/venv',
        owner     => 'devpi',
        group     => 'devpi',
        mode      => '0770',
    }
    
    exec { '/srv/devpi/venv/freshinstall.bash':
        path      => '/usr/bin:/bin',
        user      => 'devpi',
        group     => 'devpi',
        unless    => '/srv/devpi/venv/bin/pip freeze | cmp --silent /srv/devpi/venv/requirements.txt -',
        subscribe => Git::Clone['operations/wheels/devpi'],
    }
    
    base::service_unit { 'devpi':
        systemd   => true,
        subscribe => Exec['/srv/devpi/venv/freshinstall.bash'],
    }
    
    nginx::site { 'devpi':
        source => 'puppet:///modules/devpi/nginx.conf',
    }
}
