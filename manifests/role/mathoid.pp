# vim: set ts=4 et sw=4:

# TODO: now that other services inhabit service cluster A, move this definition in a
# better place
@monitor_group { 'sca_eqiad': description => 'Service Cluster A servers' }

class role::mathoid::production {
    system::role { 'role::mathoid::production': }

    include ::mathoid

    ferm::service { 'mathoid':
      proto => 'tcp',
      port  => '10042'
    }

    monitor_service { 'mathoid':
      description   => 'mathoid',
      check_command => 'check_http_on_port!10042',
    }
}

class role::mathoid::beta {
    system::role { 'role::mathoid::beta': }

    include ::mathoid

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
