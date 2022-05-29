class openstack::placement::monitor(
    $active,
    $contact_groups='wmcs-bots,admins',
) {

    require openstack::placement::service

    # nagios doesn't take a bool
    if $active {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    monitoring::service { 'placement-api-http':
        ensure        => $ensure,
        description   => 'placement-api http',
        check_command => 'check_http_on_port!18778',
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }
}
