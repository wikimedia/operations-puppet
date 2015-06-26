define lvs::monitor_service_http_https (
    $ip_address,
    $uri,
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
        check_command => "check_http_lvs!${uri}",
        critical      => $critical,
    }

    @monitoring::service { "${title}_https":
        host          => $title,
        group         => 'lvs',
        description   => 'LVS HTTPS IPv4',
        check_command => "check_https_url!${uri}",
        critical      => $critical,
    }
}
