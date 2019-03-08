class openstack::nova::fullstack::monitor {

    nrpe::monitor_service { 'nova-fullstack':
        description   => 'nova instance creation test',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1: -C python -a nova-fullstack',
        contact_group => 'wmcs-team,admins',
        retries       => 2,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }
}
