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
        check_command => "check_http_url_on_port!apertium.svc.eqiad.wmnet!${port}!/listPairs",
    }

}

class role::apertium::jenkins_access {
    # Allow ssh access from the Jenkins master to the server where apertium is
    # running
    include contint::firewall::labs
}
