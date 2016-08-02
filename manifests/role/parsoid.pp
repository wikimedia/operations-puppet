# == Class: role::parsoid
class role::parsoid {

    system::role { 'role::parsoid':
        description => "Parsoid ${::realm}"
    }

    include base::firewall
    include lvs::realserver

    include ::parsoid
    # Monitor TCP Connection States
    diamond::collector { 'TcpConnStates':
        source => 'puppet:///modules/diamond/collector/tcpconnstates.py',
    }

}
