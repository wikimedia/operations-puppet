define lvs::monitor_service_http (
    $ip_address,
    $check_command,
    $critical      = 'true',
    $contact_group = 'admins'
) {
    # Virtual resource for the monitoring host
    @monitoring::host { $title:
        ip_address    => $ip_address,
        group         => 'lvs',
        critical      => 'true',
        contact_group => $contact_group,
    }
    @monitoring::service { $title:
        host          => $title,
        group         => 'lvs',
        description   => 'LVS HTTP IPv4',
        check_command => $check_command,
        critical      => $critical,
        contact_group => $contact_group,
    }
}
