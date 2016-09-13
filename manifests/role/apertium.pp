# vim: set ts=4 et sw=4:
class role::apertium(
    $port = '2737',
) {
    system::role { 'role::apertium':
        description => 'Apertium APY server'
    }

    # LVS pooling/depoling scripts
    include ::lvs::configuration
    conftool::scripts::service { 'cxserver':
        lvs_services_config => $::lvs::configuration::lvs_services,
        lvs_class_hosts     => $::lvs::configuration::lvs_class_hosts,
    }

    include ::apertium

    ferm::service { 'apertium_http':
        proto => 'tcp',
        port  => $port,
    }

    monitoring::service { 'apertium':
        description   => 'apertium apy',
        check_command => "check_http_hostheader_port_url!apertium.svc.${::site}.wmnet!${port}!/listPairs",
    }

}
