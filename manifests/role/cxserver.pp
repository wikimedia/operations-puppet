# vim: set ts=4 et sw=4:

# We do not have monitoring yet
#@monitor_group { 'cxserver_eqiad': description => 'eqiad cxserver servers' }
#@monitor_group { 'cxserver_pmtpa': description => 'pmtpa cxserver servers' }

# Skipping production for now
#class role::cxserver::production {}

class role::cxserver::beta {
    system::role { 'role::cxserver::beta':
        description => 'cxserver server (on beta)'
    }

    class { '::cxserver':
        base_path => '/srv/deployment/cxserver/cxserver',
        node_path => '/srv/deployment/cxserver/deploy/node_modules',
        conf_path => '/srv/deployment/cxserver/config.js',
        log_dir   => '/data/project/cxserver/log',
        parsoid   => 'http://parsoid-lb.eqiad.wikimedia.org',
        require   => [
            File['/srv/deployment/cxserver'],
            File['/data/project/cxserver']
        ],
    }

    # Need to allow jenkins-deploy to reload cxserver
    sudo_user { 'jenkins-deploy': privileges => [
        # Since the "root" user is local, we cant add the sudo policy in
        # OpenStack manager interface at wikitech
        'ALL = (root)  NOPASSWD:/usr/sbin/service cxserver restart',
    ] }

    # Make sure the log directory parent exists on beta
    file { '/data/project/cxserver':
        ensure => directory,
        owner  => cxserver,
        group  => cxserver,
        mode   => '0775',
    }

    # cxserver repositories and config under /srv/deployment/cxserver
    file { '/srv/deployment/cxserver':
        ensure => directory,
        owner  => jenkins-deploy,
        group  => wikidev,
        mode   => '0755',
    }

    # We have to explicitly open the cxserver port (bug 45868)
    ferm::service { 'cxserver_http':
        proto => 'tcp',
        port  => $cxserver_port,
    }

    # Allow ssh access from the Jenkins master to the server where cxserver is
    # running
    include contint::firewall::labs

    # Instance got to be a Jenkins slave so we can update cxserver whenever a
    # change is made on mediawiki/services/cxserver (NL: /deploy???) repository
    include role::ci::slave::labs::common
    # Also need the slave scripts for multi-git.sh
    include contint::slave-scripts
}
