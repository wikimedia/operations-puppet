class openstack::cinder::monitor(
    $active,
    $critical=false,
    $contact_groups='wmcs-bots,admins',
) {

    require openstack::cinder::service

    # nagios doesn't take a bool
    if $active {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    monitoring::service { 'cinder-api':
        ensure        => $ensure,
        description   => 'cinder-api http',
        check_command => 'check_http_on_port!8776',
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }

    nrpe::monitor_service { 'check_cinder_scheduler_process':
        ensure        => $ensure,
        critical      => $critical,
        description   => 'cinder-scheduler process',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python.* /usr/bin/cinder-scheduler'",
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }
}
