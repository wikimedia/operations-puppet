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
    base_path => '/srv/deployment/mathoid/mathoid',
    node_path => '/srv/deployment/mathoid/mathoid/node_modules',
    conf_path => '/srv/deployment/mathoid/mathoid/mathoid.config.json',
    log_dir   => '/var/log/mathoid',
    require   => [
      File['/srv/deployment/mathoid/mathoid']
    ]
    }

file { '/srv/deployment/mathoid/mathoid':
ensure => directory,
}
    group { 'mathoid':
        ensure => present,
        name   => 'mathoid',
        system => true,
    }

    user { 'mathoid':
        gid           => 'mathoid',
        home          => '/srv/deployment/mathoid/mathoid',
        managehome    => true,
        system        => true,
    }

    # Jenkins copy repositories and config under /srv/deployment
    file { '/srv/deployment':
        ensure => directory,
        owner  => root,
        group  => root,
        mode   => '0755',
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
