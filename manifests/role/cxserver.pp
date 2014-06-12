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
        ensure => present,
        owner  => jenkins-deploy,
        group  => wikidev,
        mode   => '0555',
        source => 'puppet:///files/misc/cxserver-config-beta.js',
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

    # NL: So the following rules make it possible for the cxserver call back to the labs
    # projects. The only things cxserver needs to access is the parsoid url. The reason
    # the labs url did not work was this I think. If we use the production parsoid url
    # we do not need this at all, but I think it would be a good idea to use the labs
    # parsoid when running in labs. I have no idea though what IPs and ports we need
    # to allow for that though.

    # Beta parsoid server has some ferm DNAT rewriting rules (bug 45868) so we
    # have to explicitly allow parsoid port 8000
    ferm::service { 'http':
        proto => 'tcp',
        port  => '8000'
    }
    ferm::rule { 'ssh-from-beta-bastion':
        rule => 'proto tcp dport ssh { saddr 10.4.0.58 ACCEPT; }',
    }

    # Instance got to be a Jenkins slave so we can update cxserver whenever a
    # change is made on mediawiki/services/cxserver (NL: /deploy???) repository
    include role::ci::slave::labs::common
    # Also need the slave scripts for multi-git.sh
    include contint::slave-scripts

    # Allow ssh access from the Jenkins master to the server where cxserver is running
    include contint::firewall::labs
}
