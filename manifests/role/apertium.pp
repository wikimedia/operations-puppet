# vim: set ts=4 et sw=4:
class role::apertium(
    $port = '2737',
) {
    system::role { 'role::apertium':
        description => 'Apertium APY server'
    }

    include ::apertium

    ferm::service { 'apertium_http':
        proto => 'tcp',
        port  => $port,
    }

    monitoring::service { 'apertium':
        description   => 'apertium apy',
        check_command => "check_http_hostheader_port_url!apertium.svc.eqiad.wmnet!${port}!/listPairs",
    }

}
