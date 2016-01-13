# vim: set ts=4 et sw=4:
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

    ferm::service { 'parsoid':
        proto => 'tcp',
        port  => '8000',
    }
}

class role::parsoid::production {
    system::role { 'role::parsoid::production':
        description => 'Parsoid server'
    }

    include role::parsoid::common
    include standard
    include lvs::realserver
    include base::firewall

    package { 'parsoid/deploy':
        provider => 'trebuchet',
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
    }

    file { '/var/lib/parsoid/deploy':
        ensure => link,
        target => '/srv/deployment/parsoid/deploy',
    }

    file { '/etc/init/parsoid.conf':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => '0444',
        source => 'puppet:///files/misc/parsoid.upstart',
    }

    file { '/var/log/parsoid':
        ensure => directory,
        owner  => parsoid,
        group  => parsoid,
        mode   => '0775',
    }

    $parsoid_log_file = '/var/log/parsoid/parsoid.log'
    #TODO: Should we explicitly set this to '/srv/deployment/parsoid/deploy/node_modules'
    #just like beta labs
    $parsoid_node_path = '/var/lib/parsoid/deploy/node_modules'
    $parsoid_settings_file = '/srv/deployment/parsoid/deploy/conf/wmf/localsettings.js'
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
        ensure  => present,
        command => '/usr/sbin/logrotate /etc/logrotate.d/parsoid',
        user    => 'root',
        hour    => '*',
        minute  => '12',
        require => File['/etc/logrotate.d/parsoid'],
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

    monitoring::service { 'parsoid':
        description   => 'Parsoid',
        check_command => 'check_http_on_port!8000',
    }
    # until logging is handled differently, rt 6851
    nrpe::monitor_service { 'parsoid_disk_space':
        description  => 'parsoid disk space',
        nrpe_command => '/usr/lib/nagios/plugins/check_disk -w 40% -c 3% -l -e',
        critical     => true,
    }

    # Monitor TCP Connection States
    diamond::collector { 'TcpConnStates':
        source => 'puppet:///modules/diamond/collector/tcpconnstates.py',
    }
}

class role::parsoid::beta {
    system::role { 'role::parsoid::beta':
        description => 'Parsoid server (on beta)'
    }

    include role::parsoid::common

    sudo::user { 'jenkins-deploy': privileges => [
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

    # Delete the puppet copy of this file
    file { '/srv/deployment/parsoid/localsettings.js':
        ensure => absent,
    }

    # beta uses upstart:
    # FIXME: move users to upstart
    file { '/etc/init.d/parsoid':
        ensure => 'link',
        target => '/lib/init/upstart-job',
    }
    file { '/etc/init/parsoid.conf':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => '0444',
        source => 'puppet:///files/misc/parsoid.upstart',
    }

    $parsoid_log_file = '/data/project/parsoid/parsoid.log'
    # Make sure the directory exists on beta
    file { '/data/project/parsoid':
        ensure => directory,
        owner  => parsoid,
        group  => parsoid,
        mode   => '0775',
    }

    # For beta, override NODE_PATH
    # The packages are installed by Jenkins via npm install using pinned
    # versions in npm-shrinkwrap.json
    $parsoid_node_path = '/srv/deployment/parsoid/parsoid/node_modules'

    # Override PARSOID_SETTINGS_FILE
    # The setting file is in parsoid/deploy.git
    $parsoid_settings_file = '/srv/deployment/parsoid/deploy/conf/wmf/betalabs.localsettings.js'

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

    # Instance got to be a Jenkins slave so we can update Parsoid whenever a
    # change is made on mediawiki/services/parsoid repository
    include role::ci::slave::labs::common
    # Also need the slave scripts for multi-git.sh
    include contint::slave_scripts
}

# This role is used by testing services
# Ex: Parsoid roundtrip testing, Parsoid & PHP parser visual diff testing
class role::parsoid::testing {
    system::role { 'role::parsoid::testing':
        description => 'Parsoid server (rt-testing, visual-diffing, etc.)'
    }

    include role::parsoid::common

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
    }

    # We clone the git repo and let testing services
    # update / modify the repo as appropriate
    # (via scripts, manually, however).
    git::clone { 'mediawiki/services/parsoid/deploy':
        owner     => 'root',
        group     => 'wikidev',
        # FIXME: Should we move this to /srv/parsoid ?
        # I am picking /usr/lib to minimize changes to
        # ruthenium setup.
        directory => '/usr/lib/parsoid',
        before    => Service['parsoid'],
    }

    file { '/etc/init/parsoid.conf':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => '0444',
        source => 'puppet:///files/misc/parsoid.upstart',
        before => Service['parsoid'],
    }

    file { '/var/log/parsoid':
        ensure => directory,
        owner  => parsoid,
        group  => parsoid,
        mode   => '0775',
        before => Service['parsoid'],
    }

    $parsoid_log_file = '/var/log/parsoid/parsoid.log'
    $parsoid_node_path = '/usr/lib/parsoid/deploy/node_modules'
    # default local settings -- test setups provide their own settings
    $parsoid_settings_file = '/usr/lib/parsoid/src/localsettings.js'
    $parsoid_base_path = '/usr/lib/parsoid/deploy/src'

    #TODO: Duplication of code, deduplicate somehow
    file { '/etc/default/parsoid':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('misc/parsoid.default.erb'),
        before  => Service['parsoid'],
    }

    service { 'parsoid':
        hasstatus  => true,
        hasrestart => true,
        provider   => 'upstart',
        subscribe  => [
            File['/etc/default/parsoid'],
            File['/etc/init/parsoid.conf'],
        ],
    }
}
