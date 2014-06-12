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

    # KM/NL: Use production instance URL instead of 'http://10.68.16.145/'
    $cxserver_parsoid_url = 'http://parsoid-lb.eqiad.wikimedia.org'
    $cxserver_port = 8080

    class { 'cxserver':
        base_path        => '/srv/deployment/cxserver/cxserver',
        node_path        => '/srv/deployment/cxserver/deploy/node_modules',
        cxserver_log_dir => '/data/project/cxserver/log',
        log_file         => '${cxserver_log_dir}/main.log'
    }

    # Need to allow jenkins-deploy to reload cxserver
    sudo_user { 'jenkins-deploy': privileges => [
        # Since the "root" user is local, we cant add the sudo policy in
        # OpenStack manager interface at wikitech
        'ALL = (root)  NOPASSWD:/usr/sbin/service cxserver restart',
    ] }

    # Make sure the log directory exists on beta
    file { ['/data/project/cxserver', "${cxserver_log_dir}"]:
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

    # This is the beta specific cxserver configuration.
    # There will be a symlink in ./cxserver to this file.
    file { '/srv/deployment/cxserver/config.js':
        ensure  => present,
        owner   => jenkins-deploy,
        group   => wikidev,
        mode    => '0555',
        content => template('misc/cxserver.config.erb'),
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
