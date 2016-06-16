class role::parsoid {

    system::role { 'role::parsoid':
        description => "Parsoid ${::realm}"
    }

    include base::firewall
    include lvs::realserver

    include ::parsoid

    ferm::service { 'parsoid':
        proto => 'tcp',
        port  => '8000',
    }

    # until logging is handled differently, rt 6851
    nrpe::monitor_service { 'parsoid_disk_space':
        description  => 'parsoid disk space',
        nrpe_command => '/usr/lib/nagios/plugins/check_disk -w 40% -c 3% -l -e',
        critical     => true,
    }

    # Monitor TCP Connection States
    diamond::collector { 'TcpConnStates':
        source => 'puppet:///modules/diamond/collector/tcpconnstates.py',
    }

}
