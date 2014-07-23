# vim: set ts=4 et sw=4:

# We do not have monitoring yet
#@monitor_group { 'mathoid_eqiad': description => 'eqiad mathoid servers' }

# Skipping production for now
#class role::mathoid::production {
#    system::role { 'role::mathoid::production':
#        description => 'mathoid server'
#    }
#
#    deployment::target { 'mathoid': }
#}

class role::mathoid::beta {
    system::role { 'role::mathoid::beta':
        description => 'mathoid server (on beta)'
    }

  class { '::mathoid':
    base_path => '/srv/deployment/mathoid',
    node_path => '/srv/deployment/mathoid/node_modules',
    conf_path => '/srv/deployment/mathoid/config.js',
    log_dir   => '/data/project/mathoid/log',
    require   => [
      File['/srv/deployment/mathoid'],
      File['/data/project/mathoid']
    ],
    }
    sudo_user { 'jenkins-deploy': privileges => [
        # Need to allow jenkins-deploy to reload mathoid
        # Since the "root" user is local, we cant add the sudo policy in
        # OpenStack manager interface at wikitech
        # TODO: adjust for upstart!
        'ALL = (root) NOPASSWD:/usr/sbin/service mathoid restart'
    ] }


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
    file { '/srv/deployment/mathoid/mathoid.config.json':
        ensure => present,
        owner  => jenkins-deploy,
        group  => wikidev,
        mode   => '0555',
        source => 'puppet:///files/misc/mathoid.config.json',
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

    # Make sure the directory exists on beta
    file { '/data/project/mathoid':
        ensure => directory,
        owner  => mathoid,
        group  => mathoid,
        mode   => '0775',
    }


    # Beta mathoid server has some ferm DNAT rewriting rules (bug 45868) so we
    # have to explicitly allow mathoid port 8000
    ferm::service { 'http':
        proto => 'tcp',
        port  => '10042'
    }

    # Allow ssh access from the Jenkins master to the server where mathoid is
    # running
    include contint::firewall::labs

    # Instance got to be a Jenkins slave so we can update mathoid whenever a
    # change is made on mediawiki/services/mathoid repository
    include role::ci::slave::labs::common
    # Also need the slave scripts for multi-git.sh
    include contint::slave-scripts

}
