# vim: set ts=4 et sw=4:

class role::apertium::production {
    system::role { 'role::apertium::production':
        description => 'Apertium APY server'
    }

    # Define Apertium port
    $apertium_port = hiera('role::apertium::apertium_port', '2737')

    include ::apertium

    # We have to explicitly open the apertium port (bug T47868)
    ferm::service { 'apertium_http':
        proto => 'tcp',
        port  => $apertium_port,
    }

    monitor_service { 'apertium':
        description   => 'apertium apy',
        check_command => "check_http_on_port!${apertium_port}",
    }
}

class role::apertium::beta {
    system::role { 'role::apertium::beta':
        description => 'Apertium APY server (on beta)'
    }

    # Define Apertium port
    $apertium_port = hiera('role::apertium::apertium_port', '2737')

    include ::apertium

    # Need to allow jenkins-deploy to reload apertium
    sudo::user { 'jenkins-deploy': privileges => [
        # Since the "root" user is local, we cant add the sudo policy in
        # OpenStack manager interface at wikitech
        'ALL = (root)  NOPASSWD:/usr/sbin/service apertium-apy restart',
    ] }

    # We have to explicitly open the apertium port (bug T47868)
    ferm::service { 'apertium_http':
        proto => 'tcp',
        port  => $apertium_port,
    }

    # Allow ssh access from the Jenkins master to the server where apertium is
    # running
    include contint::firewall::labs
}
