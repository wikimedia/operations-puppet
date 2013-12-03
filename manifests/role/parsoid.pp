# vim: set ts=4 et sw=4:

@monitor_group { 'parsoid_eqiad': description => 'eqiad parsoid servers' }
@monitor_group { 'parsoid_pmtpa': description => 'pmtpa parsoid servers' }

class role::parsoid::common {
    package { [
        'nodejs',
        'npm',
        'build-essential',
        ]: ensure => latest,
    }

    file { '/var/lib/parsoid':
        ensure => directory,
        owner  => parsoid,
        group  => wikidev,
        mode   => '2775',
    }

    file { '/etc/init.d/parsoid':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => '0555',
        source => 'puppet:///files/misc/parsoid.init',
    }

    file { '/usr/bin/parsoid':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => '0555',
        source => 'puppet:///files/misc/parsoid',
    }

    generic::systemuser { 'parsoid':
        name          => 'parsoid',
        default_group => 'parsoid',
        home          => '/var/lib/parsoid',
    }

    service { 'parsoid':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        enable     => true,
        require    => File['/etc/init.d/parsoid'],
    }

}

class role::parsoid::production {
    system::role { 'role::parsoid::production':
        description => 'Parsoid server'
    }

    include role::parsoid::common

    deployment::target { 'parsoid': }

    file { '/var/lib/parsoid/Parsoid':
        ensure => link,
        target => '/srv/deployment/parsoid/Parsoid',
    }

    monitor_service { 'parsoid':
        description   => 'Parsoid',
        check_command => 'check_http_on_port!8000',
    }
}

class role::parsoid::beta {
    system::role { 'role::parsoid::beta':
        description => 'Parsoid server (on beta)'
    }

    include role::parsoid::common

    sudo_user { 'jenkins-deploy': privileges => [
        # Need to allow jenkins-deploy to reload parsoid
        # Since the "root" user is local, we cant add the sudo policy in
        # OpenStack manager interface at wikitech
        'ALL = (root) NOPASSWD:/etc/init.d/parsoid',
    ] }

    file { '/var/lib/parsoid/Parsoid':
        ensure => link,
        target => '/data/project/apache/common-local/php-master/extensions/Parsoid',
        owner  => parsoid,
        group  => wikidev,
        mode   => '2775',
    }
}
