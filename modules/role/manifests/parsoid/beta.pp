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
        source => 'puppet:///modules/parsoid/parsoid.upstart',
    }

    $parsoid_log_file = '/var/log/parsoid/parsoid.log'
    # Make sure the directory exists on beta
    file { '/var/log/parsoid':
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
        content => template('parsoid/parsoid.default.erb'),
        require => File['/var/log/parsoid'],
    }

    file { '/etc/logrotate.d/parsoid':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('parsoid/parsoid.logrotate.erb'),
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
