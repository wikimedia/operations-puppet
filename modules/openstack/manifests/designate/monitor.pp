# Designate provides DNSaaS services for OpenStack
# https://wiki.openstack.org/wiki/Designate

class openstack::designate::monitor (
    $active,
    $critical=false,
    $contact_groups='wmcs-bots,admins',
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
        ensure        => $ensure,
        critical      => $critical,
        description   => 'designate-sink process',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/designate-sink'",
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }

    nrpe::monitor_service { 'check_designate_api_process':
        ensure        => $ensure,
        critical      => $critical,
        description   => 'designate-api process',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/designate-api'",
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }

    nrpe::monitor_service { 'check_designate_central_process':
        ensure        => $ensure,
        critical      => $critical,
        description   => 'designate-central process',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/designate-central'",
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }

    nrpe::monitor_service { 'check_designate_mdns':
        ensure        => $ensure,
        critical      => $critical,
        description   => 'designate-mdns process',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/designate-mdns'",
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }

    nrpe::monitor_service { 'check_designate_pool-manager':
        ensure        => $ensure,
        critical      => $critical,
        description   => 'designate-pool-manager process',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/designate-pool-manager'",
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }

    monitoring::service { 'designate-api-http':
        ensure        => $ensure,
        description   => 'designate-api http',
        check_command => 'check_http_on_port!9001',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }
}
