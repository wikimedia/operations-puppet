# This is the placement-api service for Openstack Nova.
# It provides a REST api that  Wikitech and Horizon use to manage VMs.
class openstack::nova::placement::monitor(
    Boolean $active,
    Boolean $critical=false,
    String $contact_groups='wmcs-bots,admins',
    ) {

    # monitoring::service doesn't take a bool
    if $active {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    nrpe::monitor_service { 'check_nova_placement_process':
        ensure        => $ensure,
        critical      => $critical,
        description   => 'nova-placement-api process',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python.* /usr/bin/nova-placement-api'",
        contact_group => $contact_groups,
    }

    monitoring::service { 'nova-placement-api-http':
        ensure        => $ensure,
        critical      => $critical,
        description   => 'nova-placement-api http',
        check_command => 'check_http_on_port!8778',
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }
}
