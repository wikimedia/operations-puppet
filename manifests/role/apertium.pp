# vim: set ts=4 et sw=4:

# We do not have monitoring yet
#@monitor_group { 'apertium_eqiad': description => 'eqiad apertium servers' }
#@monitor_group { 'apertium_pmtpa': description => 'pmtpa apertium servers' }

# Skipping production for now
#class role::apertium::production {}

class role::apertium::beta {
    system::role { 'role::apertium::beta':
        description => 'Apertium APY server (on beta)'
    }

    # Need to allow jenkins-deploy to reload apertium
    sudo_user { 'jenkins-deploy': privileges => [
        # Since the "root" user is local, we cant add the sudo policy in
        # OpenStack manager interface at wikitech
        'ALL = (root)  NOPASSWD:/usr/sbin/service apy restart',
    ] }

    # We have to explicitly open the apertium port (bug 45868)
    ferm::service { 'apertium_http':
        proto => 'tcp',
        port  => $apertium_port,
    }

    # Allow ssh access from the Jenkins master to the server where apertium is
    # running
    include contint::firewall::labs

    # Instance got to be a Jenkins slave so we can update apertium whenever a
    # change is made on mediawiki/services/apertium (NL: /deploy???) repository
    include role::ci::slave::labs::common
    # Also need the slave scripts for multi-git.sh
    include contint::slave-scripts
}
