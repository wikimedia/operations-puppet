# Designate provides DNSaaS services for OpenStack
# https://wiki.openstack.org/wiki/Designate

class openstack2::designate::monitor (
    $active,
    $critical = true,
    ) {

    # monitoring::service doesn't take a bool
    if $active {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    # Page if designate processes die and 'critical' is true.  We only have one of each of these,
    #  and new instance creation will be very broken if services die.
    nrpe::monitor_service { 'check_designate_sink_process':
        ensure       => $ensure,
        description  => 'designate-sink process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/designate-sink'",
        critical     => $critical,
    }

    nrpe::monitor_service { 'check_designate_api_process':
        ensure       => $ensure,
        description  => 'designate-api process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/designate-api'",
        critical     => $critical,
    }

    nrpe::monitor_service { 'check_designate_central_process':
        ensure       => $ensure,
        description  => 'designate-central process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/designate-central'",
        critical     => $critical,
    }

    nrpe::monitor_service { 'check_designate_mdns':
        ensure       => $ensure,
        description  => 'designate-mdns process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/designate-mdns'",
        critical     => $critical,
    }

    nrpe::monitor_service { 'check_designate_pool-manager':
        ensure       => $ensure,
        description  => 'designate-pool-manager process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/designate-pool-manager'",
        critical     => $critical,
    }

    monitoring::service { 'designate-api-http':
        ensure        => $ensure,
        description   => 'designate-api http',
        check_command => 'check_http_on_port!9001',
    }
}
