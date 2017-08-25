# This is the api service for Openstack Nova.
# It provides a REST api that  Wikitech and Horizon use to manage VMs.
class openstack2::nova::api::monitor(
    $active,
    ) {

    # monitoring::service doesn't take a bool
    if $active {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    nrpe::monitor_service { 'check_nova_api_process':
        ensure       => $ensure,
        description  => 'nova-api process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/nova-api'",
    }

    monitoring::service { 'nova-api-http':
        ensure        => $ensure,
        description   => 'nova-api http',
        check_command => 'check_http_on_port!8774',
    }
}
