class openstack::glance::monitor(
    $contact_groups='wmcs-bots,admins',
) {
    require openstack::glance::service

    monitoring::service { 'glance-api-http':
        ensure        => 'present',
        description   => 'glance-api http',
        check_command => 'check_http_on_port!9292',
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }
}
