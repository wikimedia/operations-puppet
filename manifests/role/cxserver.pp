# vim: set ts=4 et sw=4:

# We do not have monitoring yet
#@monitor_group { 'cxserver_eqiad': description => 'eqiad cxserver servers' }
#@monitor_group { 'cxserver_pmtpa': description => 'pmtpa cxserver servers' }

class role::cxserver::common {
    package { 'nodejs':
        ensure => present,
    }
}

# Skipping production for now
#class role::cxserver::production {}

class role::cxserver::beta {
    system::role { 'role::cxserver::beta':
        description => 'cxserver server (on beta)'
    }

    include role::cxserver::common

    # Need to allow jenkins-deploy to reload cxserver
    sudo_user { 'jenkins-deploy': privileges => [
        # Since the "root" user is local, we cant add the sudo policy in
        # OpenStack manager interface at wikitech
        'ALL = (root)  NOPASSWD:/usr/sbin/service cxserver restart',
    ] }

    # FIXME should be a user in LDAP (bug 66575)
    generic::systemuser { 'cxserver':
        name          => 'cxserver',
        default_group => 'cxserver',
        home          => '/var/lib/cxserver',
    }

    $cxserver_base_path = '/srv/deployment/cxserver/deploy/src'
    $cxserver_node_path = '/srv/deployment/cxserver/deploy/node_modules'
    # The cxserver is hardcoded to look this file under base_path currently
    $cxserver_config_file = '/srv/deployment/cxserver/deploy/src/config.js'
    # NL: Pick a better port
    $cxserver_port = '8080'

    # IP from files/misc/parsoid-localsettings-beta.js
    $cxserver_parsoid_url = 'http://10.68.16.145/'
    $cxserver_log_dir = '/data/project/cxserver/log'

    # Make sure the directory exists on beta
    file { ['/data/project/cxserver', '/data/project/cxserver/log']:
        ensure => directory,
        owner  => cxserver,
        group  => cxserver,
        mode   => '0775',
    }

    # NL: The following comment is unclear. Does this module really need to ensure this is present?
    # Jenkins copy repositories and config under /srv/deployment
    file { '/srv/deployment':
        ensure => directory,
        owner  => root,
        group  => root,
        mode   => '0755',
    }

    file { '/srv/deployment/cxserver':
        ensure => directory,
        owner  => jenkins-deploy,
        group  => wikidev,
        mode   => '0755',
    }

    # This is the beta specific cxserver configuration
    file { '/srv/deployment/cxserver/deploy/src/config.js':
        ensure  => present,
        owner   => jenkins-deploy,
        group   => wikidev,
        mode    => '0555',
        content => template('misc/cxserver.config.erb'),
    }

    # The upstart configuration
    file { '/etc/init/cxserver.conf':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        source => 'puppet:///files/misc/cxserver.upstart',
    }

    # This template uses the variables defined above
    file { '/etc/default/cxserver':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('misc/cxserver.default.erb'),
        # NL: Is there no better place for this?
        require => File['/data/project/cxserver/log'],
    }

    # This template uses the variables defined above
    file { '/etc/logrotate.d/cxserver':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('misc/cxserver.logrotate.erb'),
    }

    service { 'cxserver':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        provider   => 'upstart',
        subscribe  => [
            File['/etc/default/cxserver'],
            File['/etc/init/cxserver.conf'],
        ],
    }

    # Beta parsoid server has some ferm DNAT rewriting rules (bug 45868) so we
    # have to explicitly open the cxserver port
    ferm::service { 'http':
        proto => 'tcp',
        port  => $cxserver_port,
    }

    # Allow ssh access from the Jenkins master to the server where cxserver is running
    include contint::firewall::labs
    # Allow ssh access from beta bastion
    include beta::firewall::bastionssh

    # Instance got to be a Jenkins slave so we can update cxserver whenever a
    # change is made on mediawiki/services/cxserver (NL: /deploy???) repository
    include role::ci::slave::labs::common
    # Also need the slave scripts for multi-git.sh
    include contint::slave-scripts
}
