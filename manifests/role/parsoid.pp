# vim: set ts=4 et sw=4:

@monitor_group { 'parsoid_eqiad': description => 'eqiad parsoid servers' }
@monitor_group { 'parsoid_pmtpa': description => 'pmtpa parsoid servers' }

class role::parsoid::production {

    system::role { 'role::parsoid::production': description => 'Parsoid server' }

    deployment::target { 'parsoid': }

    package { [
        'nodejs',
        'npm',
        'build-essential',
        ]: ensure => latest
    }

    file { '/var/lib/parsoid':
        ensure => directory,
        owner  => parsoid,
        group  => wikidev,
        mode   => '2775',
    }

    file { '/var/lib/parsoid/Parsoid':
        ensure => link,
        target => '/srv/deployment/parsoid/Parsoid',
    }

    file { '/etc/init.d/parsoid':
        source => 'puppet:///files/misc/parsoid.init',
        owner  => root,
        group  => root,
        mode   => '0555',
    }

    file { '/usr/bin/parsoid':
        source => 'puppet:///files/misc/parsoid',
        owner  => root,
        group  => root,
        mode   => '0555',
    }

    generic::systemuser { 'parsoid':
        name          => 'parsoid',
        default_group => 'parsoid',
        home          => '/var/lib/parsoid';
    }

    service { 'parsoid':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        enable     => true,
        require    => [File['/etc/init.d/parsoid']];
    }

    monitor_service { 'parsoid': description => 'Parsoid', check_command => 'check_http_on_port!8000' }
}
