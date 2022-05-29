class openstack::glance::monitor(
    String  $contact_groups,
    Boolean $active = true,
) {
    require openstack::glance::service

    monitoring::service { 'glance-api-http':
        ensure        => $active.bool2str('present', 'absent'),
        description   => 'glance-api http',
        check_command => 'check_http_on_port!19292',
        contact_group => $contact_groups,
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Troubleshooting',
    }
}
