# vim: set ts=4 et sw=4:

# TODO: now that other services inhabit service cluster A, move this definition in a
# better place
@monitor_group { 'sca_eqiad': description => 'Service Cluster A servers' }

class role::mathoid::production {
    system::role { 'role::mathoid::production':
        description => 'mathoid server'
    }

    class { '::mathoid':
      base_path => '/srv/deployment/mathoid/mathoid',
      node_path => '/srv/deployment/mathoid/mathoid/node_modules',
      conf_path => '/srv/deployment/mathoid/mathoid/mathoid.config.json',
      log_dir   => '/var/log/mathoid',
      require   => Package['mathoid/mathoid'],
    }

    package { 'mathoid/mathoid':
        provider => 'trebuchet',
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

    ferm::service { 'mathoid':
      proto => 'tcp',
      port  => '10042'
    }

    monitor_service { 'mathoid':
      description => 'mathoid',
      check_command => 'check_http_on_port!10042',
    }
}

class role::mathoid::beta {
    system::role { 'role::mathoid::beta':
        description => 'mathoid server (on beta)'
    }

    class { '::mathoid':
        base_path => '/srv/deployment/mathoid/mathoid',
        node_path => '/srv/deployment/mathoid/mathoid/node_modules',
        conf_path => '/srv/deployment/mathoid/mathoid/mathoid.config.json',
        log_dir   => '/var/log/mathoid',
        require   => Package['mathoid'],
    }

    package { 'mathoid':
        provider => 'trebuchet',
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

    # Beta mathoid server has some ferm DNAT rewriting rules (bug 45868) so we
    # have to explicitly allow mathoid port 10042
    ferm::service { 'mathoid':
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
