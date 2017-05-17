# == Class: role::parsoid
#
# filtertags: labs-project-deployment-prep
class role::parsoid {

    system::role { 'parsoid':
        description => "Parsoid ${::realm}"
    }

    include ::standard
    include ::base::firewall

    if hiera('has_lvs', true) {
        include role::lvs::realserver
    }

    include ::parsoid
    # Monitor TCP Connection States
    diamond::collector { 'TcpConnStates':
        source => 'puppet:///modules/diamond/collector/tcpconnstates.py',
    }

}
