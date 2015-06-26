define lvs::monitor_service6_http_https (
    $ip_address,
    $uri,
    $critical = 'true'
) {
    # Virtual resource for the monitoring host
    @monitoring::host { "${title}_ipv6":
        ip_address => $ip_address,
        group      => 'lvs',
        critical   => 'true',
    }

    @monitoring::service { "${title}_ipv6":
        host          => "${title}_ipv6",
        group         => 'lvs',
        description   => 'LVS HTTP IPv6',
        check_command => "check_http_lvs!${uri}",
        critical      => $critical,
    }

    @monitoring::service { "${title}_ipv6_https":
        host          => "${title}_ipv6",
        group         => 'lvs',
        description   => 'LVS HTTPS IPv6',
        check_command => "check_https_url!${uri}",
        critical      => $critical,
    }
}
