# == Class: role::parsoid
class role::parsoid {

    system::role { 'role::parsoid':
        description => "Parsoid ${::realm}"
    }

    include base::firewall
    include lvs::realserver

    # LVS pooling/depoling scripts
    include ::lvs::configuration
    conftool::scripts::service { 'parsoid':
        lvs_services_config => $::lvs::configuration::lvs_services,
        lvs_class_hosts     => $::lvs::configuration::lvs_class_hosts,
    }

    include ::parsoid
    # Monitor TCP Connection States
    diamond::collector { 'TcpConnStates':
        source => 'puppet:///modules/diamond/collector/tcpconnstates.py',
    }

}
