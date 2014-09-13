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

}

class role::parsoid::production {
    system::role { 'role::parsoid::production':
        description => 'Parsoid server'
    }

    include role::parsoid::common

    deployment::target { 'parsoid': }

    group { 'parsoid':
        ensure => present,
        name   => 'parsoid',
        system => true,
    }

    user { 'parsoid':
        gid           => 'parsoid',
        home          => '/var/lib/parsoid',
        managehome    => true,
        system        => true,
    }

    file { '/var/lib/parsoid/deploy':
        ensure => link,
        target => '/srv/deployment/parsoid/deploy',
    }

    file { '/etc/init/parsoid.conf':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        source  => 'puppet:///files/misc/parsoid.upstart',
    }
    file { '/var/log/parsoid':
        ensure => directory,
        owner  => parsoid,
        group  => parsoid,
        mode   => '0775',
    }

    $parsoid_log_file = '/var/log/parsoid/parsoid.log'
    $parsoid_node_path = '/var/lib/parsoid/deploy/node_modules'
    $parsoid_settings_file = '../conf/wmf/localsettings.js'
    $parsoid_base_path = '/var/lib/parsoid/deploy/src'

    #TODO: Duplication of code from beta class, deduplicate somehow
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

    cron { 'parsoid-hourly-logrot':
        ensure   => present,
        command  => '/usr/sbin/logrotate /etc/logrotate.d/parsoid',
        user     => 'root',
        hour     => '*',
        minute   => '12',
        require  => File['/etc/logrotate.d/parsoid'],
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
    }

    monitor_service { 'parsoid':
        description   => 'Parsoid',
        check_command => 'check_http_on_port!8000',
    }
    # until logging is handled differently, rt 6851
    nrpe::monitor_service { 'parsoid_disk_space':
        description   => 'parsoid disk space',
        nrpe_command  => '/usr/lib/nagios/plugins/check_disk -w 40% -c 3% -l -e',
        critical      => true,
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
        # TODO: adjust for upstart!
        'ALL = (root) NOPASSWD:/etc/init.d/parsoid',
    ] }

    file { '/var/lib/parsoid/Parsoid':
        ensure => link,
        target => '/srv/mediawiki/php-master/extensions/Parsoid',
        owner  => parsoid,
        group  => wikidev,
        mode   => '2775',
    }

    # Jenkins copy repositories and config under /srv/deployment
    file { '/srv/deployment':
        ensure => directory,
        owner  => root,
        group  => root,
        mode   => '0755',
    }
    file { '/srv/deployment/parsoid':
        ensure => directory,
        owner  => jenkins-deploy,
        group  => wikidev,
        mode   => '0755',
    }
    file { '/srv/deployment/parsoid/localsettings.js':
        ensure => present,
        owner  => jenkins-deploy,
        group  => wikidev,
        mode   => '0555',
        source => 'puppet:///files/misc/parsoid-localsettings-beta.js',
    }

    # beta uses upstart:
    # FIXME: move users to upstart
    file { '/etc/init.d/parsoid':
        ensure => 'link',
        target => '/lib/init/upstart-job',
    }
    file { '/etc/init/parsoid.conf':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        source  => 'puppet:///files/misc/parsoid.upstart',
    }

    $parsoid_log_file = '/data/project/parsoid/parsoid.log'
    # Make sure the directory exists on beta
    file { '/data/project/parsoid':
        ensure => directory,
        owner  => parsoid,
        group  => parsoid,
        mode   => '0775',
    }

    # For beta, override NODE_PATH:
    $parsoid_node_path = '/srv/deployment/parsoid/deploy/node_modules'
    # Also override PARSOID_SETTINGS_FILE
    $parsoid_settings_file = '/srv/deployment/parsoid/localsettings.js'

    # Checkout of mediawiki/services/parsoid
    $parsoid_base_path = '/srv/deployment/parsoid/parsoid'

    file { '/etc/default/parsoid':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('misc/parsoid.default.erb'),
        require => File['/data/project/parsoid'],
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
    }

    # Beta parsoid server has some ferm DNAT rewriting rules (bug 45868) so we
    # have to explicitly allow parsoid port 8000
    ferm::service { 'http':
        proto => 'tcp',
        port  => '8000'
    }

    # Instance got to be a Jenkins slave so we can update Parsoid whenever a
    # change is made on mediawiki/services/parsoid repository
    include role::ci::slave::labs::common
    # Also need the slave scripts for multi-git.sh
    include contint::slave-scripts

}
