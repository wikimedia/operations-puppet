# This is the api service for Openstack Nova.
# It provides a REST api that  Wikitech and Horizon use to manage VMs.
class openstack::nova::api::monitor(
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

    nrpe::monitor_service { 'check_nova_api_process':
        ensure        => $ensure,
        critical      => $critical,
        description   => 'nova-api process',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array 'nova-api-uwsgi'",
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin',
    }

    nrpe::monitor_service { 'check_novametadata_api_process':
        ensure        => $ensure,
        critical      => $critical,
        description   => 'nova metadata api process',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array 'nova-api-metadata-uwsgi.ini'",
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin',
    }

    monitoring::service { 'nova-api-http':
        ensure        => $ensure,
        critical      => $critical,
        description   => 'nova-api http',
        check_command => 'check_http_on_port!18774',
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }
}
