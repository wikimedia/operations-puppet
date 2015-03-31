# vim: set ts=4 et sw=4:

@monitoring::group { 'parsoid_eqiad': description => 'eqiad parsoid servers' }

class role::parsoid (
    $parsoid_log_dir = '/var/log/parsoid/',
    $parsoid_log_file = '/var/log/parsoid/parsoid.log',
    $parsoid_user = 'parsoid',
    $parsoid_group = 'parsoid',
    $parsoid_settings_file = '/srv/deployment/parsoid/deploy/conf/wmf/localsettings.js',
    $parsoid_node_path = '/var/lib/parsoid/deploy/node_modules',
    $parsoid_base_path = '/var/lib/parsoid/deploy/src'
) {
    system::role { 'role::parsoid::production':
        description => 'Parsoid server'
    }

    include standard

    if ($::realm == 'production') {
        include admin
    }

    if hiera('has_lvs', true) {
        include lvs::realserver
    }

    include base::firewall

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

    ferm::service { 'parsoid':
        proto => 'tcp',
        port  => '8000',
    }

    group { 'parsoid':
        ensure => present,
        name   => 'parsoid',
        system => true,
    }

    user { 'parsoid':
        gid        => 'parsoid',
        home       => '/var/lib/parsoid',
        managehome => true,
        system     => true,
        require    => Group['parsoid'],
    }

    file { '/var/lib/parsoid/deploy':
        ensure  => link,
        target  => '/srv/deployment/parsoid/deploy',
        require => User['parsoid'],
    }

    file { $parsoid_log_dir:
        ensure  => directory,
        mode    => '0775',
        owner   => $parsoid_user,
        group   => $parsoid_group,
        require => User['parsoid'],
    }

    file { '/etc/init/parsoid.conf':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        source  => 'puppet:///files/misc/parsoid.upstart',
    }

    file { '/etc/default/parsoid':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('misc/parsoid.default.erb'),
        require => File[$parsoid_log_dir],
    }

    package { 'parsoid/deploy':
        provider => 'trebuchet',
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
        require    => Package['parsoid/deploy'],
    }

    cron { 'parsoid-hourly-logrot':
        ensure   => present,
        command  => '/usr/sbin/logrotate /etc/logrotate.d/parsoid',
        user     => 'root',
        hour     => '*',
        minute   => '12',
        require  => File['/etc/logrotate.d/parsoid'],
    }

    monitoring::service { 'parsoid':
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

    class { role::parsoid:
        parsoid_log_dir       => '/data/project/parsoid',
        parsoid_log_file      => '/data/project/parsoid/parsoid.log',
        parsoid_settings_file => '/srv/deployment/parsoid/deploy/conf/wmf/betalabs.localsettings.js'
    }

    sudo::user { 'jenkins-deploy': privileges => [
        # Need to allow jenkins-deploy to reload parsoid
        # Since the "root" user is local, we cant add the sudo policy in
        # OpenStack manager interface at wikitech
        # TODO: adjust for upstart!
        'ALL = (root) NOPASSWD:/etc/init.d/parsoid',
    ] }

    # beta uses upstart:
    # FIXME: move users to upstart
    file { '/etc/init.d/parsoid':
        ensure => 'link',
        target => '/lib/init/upstart-job',
    }

    # Instance got to be a Jenkins slave so we can update Parsoid whenever a
    # change is made on mediawiki/services/parsoid repository
    include role::ci::slave::labs::common
    # Also need the slave scripts for multi-git.sh
    include contint::slave-scripts

}
