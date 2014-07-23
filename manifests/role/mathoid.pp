# vim: set ts=4 et sw=4:

@monitor_group { 'mathoid_eqiad': description => 'eqiad mathoid servers' }

class role::mathoid::common {
    package { [
        'nodejs',
        'npm',
        'build-essential',
        ]: ensure => present,
    }

    file { '/var/lib/mathoid':
        ensure => directory,
        owner  => mathoid,
        group  => wikidev,
        mode   => '2775',
    }

    file { '/usr/bin/mathoid':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => '0555',
        source => 'puppet:///files/misc/mathoid',
    }

}

class role::mathoid::production {
    system::role { 'role::mathoid::production':
        description => 'mathoid server'
    }

    include role::mathoid::common

    deployment::target { 'mathoid': }

    group { 'mathoid':
        ensure => present,
        name   => 'mathoid',
        system => true,
    }

    user { 'mathoid':
        gid           => 'mathoid',
        home          => '/var/lib/mathoid',
        managehome    => true,
        system        => true,
    }

    file { '/var/lib/mathoid/deploy':
        ensure => link,
        target => '/srv/deployment/mathoid/deploy',
    }

    file { '/etc/init/mathoid.conf':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        source => 'puppet:///files/misc/mathoid.upstart',
    }
    file { '/var/log/mathoid':
        ensure => directory,
        owner  => mathoid,
        group  => mathoid,
        mode   => '0775',
    }

    $mathoid_log_file = '/var/log/mathoid/mathoid.log'
    $mathoid_node_path = '/var/lib/mathoid/deploy/node_modules'
    $mathoid_settings_file = '../conf/wmf/localsettings.js'
    $mathoid_base_path = '/var/lib/mathoid/deploy/src'

    #TODO: Duplication of code from beta class, deduplicate somehow
    file { '/etc/default/mathoid':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('misc/mathoid.default.erb'),
        require => File['/var/log/mathoid'],
    }

    file { '/etc/logrotate.d/mathoid':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('misc/mathoid.logrotate.erb'),
    }

    cron { 'mathoid-hourly-logrot':
        ensure  => present,
        command => '/usr/sbin/logrotate /etc/logrotate.d/mathoid',
        user    => 'root',
        hour    => '*',
        minute  => '12',
       require => File['/etc/logrotate.d/mathoid'],
    }

    service { 'mathoid':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        provider   => 'upstart',
        subscribe  => [
            File['/etc/default/mathoid'],
            File['/etc/init/mathoid.conf'],
        ],
    }

    monitor_service { 'mathoid':
        description   => 'mathoid',
        check_command => 'check_http_on_port!10042',
    }
    # until logging is handled differently, rt 6851
    # I think we can remove that for mathoid. There won't be large log files
    nrpe::monitor_service { 'mathoid_disk_space':
        description   => 'mathoid disk space',
        nrpe_command  => '/usr/lib/nagios/plugins/check_disk -w 40% -c 3% -l -e',
        critical      => true,
    }
}

class role::mathoid::beta {
    system::role { 'role::mathoid::beta':
        description => 'mathoid server (on beta)'
    }

    include role::mathoid::common

    sudo_user { 'jenkins-deploy': privileges => [
        # Need to allow jenkins-deploy to reload mathoid
        # Since the "root" user is local, we cant add the sudo policy in
        # OpenStack manager interface at wikitech
        # TODO: adjust for upstart!
        'ALL = (root) NOPASSWD:/etc/init.d/mathoid',
    ] }

    file { '/var/lib/mathoid/mathoid':
        ensure => link,
        target => '/data/project/apache/common-local/php-master/extensions/mathoid',
        owner  => mathoid,
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
    file { '/srv/deployment/mathoid':
        ensure => directory,
        owner  => jenkins-deploy,
        group  => wikidev,
        mode   => '0755',
    }
    file { '/srv/deployment/mathoid/localsettings.js':
        ensure => present,
        owner  => jenkins-deploy,
        group  => wikidev,
        mode   => '0555',
        source => 'puppet:///files/misc/mathoid-localsettings-beta.js',
    }

    # beta uses upstart:
    # FIXME: move users to upstart
    file { '/etc/init.d/mathoid':
        ensure => 'link',
        target => '/lib/init/upstart-job',
    }
    file { '/etc/init/mathoid.conf':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        source => 'puppet:///files/misc/mathoid.upstart',
    }

    $mathoid_log_file = '/data/project/mathoid/mathoid.log'
    # Make sure the directory exists on beta
    file { '/data/project/mathoid':
        ensure => directory,
        owner  => mathoid,
        group  => mathoid,
        mode   => '0775',
    }

    # For beta, override NODE_PATH:
    $mathoid_node_path = '/srv/deployment/mathoid/deploy/node_modules'
    # Also override mathoid_SETTINGS_FILE
    $mathoid_settings_file = '/srv/deployment/mathoid/localsettings.js'

    # Checkout of mediawiki/services/mathoid
    $mathoid_base_path = '/srv/deployment/mathoid/mathoid'

    file { '/etc/default/mathoid':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('misc/mathoid.default.erb'),
        require => File['/data/project/mathoid'],
    }

    file { '/etc/logrotate.d/mathoid':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('misc/mathoid.logrotate.erb'),
    }

    service { 'mathoid':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        provider   => 'upstart',
        subscribe  => [
            File['/etc/default/mathoid'],
            File['/etc/init/mathoid.conf'],
        ],
    }

    # Beta mathoid server has some ferm DNAT rewriting rules (bug 45868) so we
    # have to explicitly allow mathoid port 8000
    ferm::service { 'http':
        proto => 'tcp',
        port  => '8000'
    }

    # Instance got to be a Jenkins slave so we can update mathoid whenever a
    # change is made on mediawiki/services/mathoid repository
    include role::ci::slave::labs::common
    # Also need the slave scripts for multi-git.sh
    include contint::slave-scripts

}
