# vim: set ts=4 et sw=4:

@monitor_group { 'parsoid_eqiad': description => 'eqiad parsoid servers' }
@monitor_group { 'parsoid_pmtpa': description => 'pmtpa parsoid servers' }

class role::parsoid::common {
    package { [
        'nodejs',
        'npm',
        'build-essential',
        ]: ensure => present,
    }

    file { '/var/lib/parsoid':
        ensure => directory,
        owner  => parsoid,
        group  => wikidev,
        mode   => '2775',
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

    # production uses an init script whereas labs experiments with upstart
    file { '/etc/init.d/parsoid':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => '0555',
        source => 'puppet:///files/misc/parsoid.init',
    }
    service { 'parsoid':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        enable     => true,
        require    => File['/etc/init.d/parsoid'],
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

    # beta uses upstart:
    file { '/etc/init.d/parsoid':
        ensure => 'link',
        target => '/lib/init/upstart-job',
    }
    file { '/etc/init/parsoid.conf':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        source => 'puppet:///files/misc/parsoid.upstart',
    }
    file { '/var/log/parsoid':
        ensure => directory,
        owner  => parsoid,
        group  => parsoid,
        mode   => '0775',
    }

    $parsoid_log_file = '/var/log/parsoid/parsoid.log'

    file { '/etc/default/parsoid':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('misc/parsoid.default.erb'),
        require => File['/var/log/parsoid'],
    }

    file { '/etc/logrotate.d/parsoid':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('misc/parsoid.logrotate.erb'),
    }

    service { 'parsoid':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        provider   => 'upstart',
        subscribe  => [
            File['/etc/default/parsoid'],
            File['/etc/init/parsoid.conf'],
        ],
        require    => File['/etc/init.d/parsoid'],
    }

    # Beta parsoid server has some ferm DNAT rewriting rules (bug 45868) so we
    # have to explicitly allow parsoid port 8000
    ferm::service { 'http':
        proto => 'tcp',
        port  => '8000'
    }
    ferm::rule { 'ssh-from-beta-bastion':
        rule => 'proto tcp dport ssh { saddr 10.4.0.58 ACCEPT; }',
    }

}
