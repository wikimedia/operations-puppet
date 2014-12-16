# vim: set ts=4 et sw=4:

# Apertium is in a service cluster A.
#@monitoring::group { 'sca_eqiad': description => 'Service Cluster A servers' }

class role::apertium::production {
    system::role { 'role::apertium::production':
        description => 'Apertium APY server'
    }

    include ::apertium

    # Need to allow jenkins-deploy to reload apertium
    sudo::user { 'jenkins-deploy': privileges => [
        # Since the "root" user is local, we cant add the sudo policy in
        # OpenStack manager interface at wikitech
        'ALL = (root)  NOPASSWD:/usr/sbin/service apertium-apy restart',
    ] }

    # Define Apertium log directory and port
    $log_dir = '/var/log/apertium'
    $apertium_port = '2737'

    # We have to explicitly open the apertium port (bug 45868)
    ferm::service { 'apertium_http':
        proto => 'tcp',
        port  => $apertium_port,
    }
}

class role::apertium::beta {
    system::role { 'role::apertium::beta':
        description => 'Apertium APY server (on beta)'
    }

    include ::apertium

    # Need to allow jenkins-deploy to reload apertium
    sudo::user { 'jenkins-deploy': privileges => [
        # Since the "root" user is local, we cant add the sudo policy in
        # OpenStack manager interface at wikitech
        'ALL = (root)  NOPASSWD:/usr/sbin/service apertium-apy restart',
    ] }

    # Define Apertium log directory and port
    $log_dir = '/var/log/apertium'
    $apertium_port = '2737'

    # We have to explicitly open the apertium port (bug 45868)
    ferm::service { 'apertium_http':
        proto => 'tcp',
        port  => $apertium_port,
    }

    # Allow ssh access from the Jenkins master to the server where apertium is
    # running
    include contint::firewall::labs
}
