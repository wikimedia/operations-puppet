# lvs/init.pp

define lvs::monitor_service_custom ( $description="LVS", $ip_address, $port=80, $check_command, $retries=3 ) {
    # Virtual resource for the monitoring host
    @monitor_host { $title: ip_address => $ip_address, group => "lvs", critical => "true" }
    @monitor_service { $title: host => $title, group => "lvs", description => $description, check_command => $check_command, critical => "true", retries => $retries }
}

define lvs::monitor_service_http ( $ip_address, $check_command, $critical="true", $contact_group="admins" ) {
    # Virtual resource for the monitoring host
    @monitor_host { $title: ip_address => $ip_address, group => "lvs", critical => "true", contact_group => $contact_group }
    @monitor_service { $title: host => $title, group => "lvs", description => "LVS HTTP IPv4", check_command => $check_command, critical => $critical, contact_group => $contact_group }
}

define lvs::monitor_service_https ( $ip_address, $check_command, $port=443, $critical="true" ) {
    $title_https = "${title}_https"
    # Virtual resource for the monitoring host
    @monitor_host { $title_https: ip_address => $ip_address, group => "lvs", critical => "true" }
    @monitor_service { $title_https: host => $title, group => "lvs", description => "LVS HTTPS IPv4", check_command => $check_command, critical => $critical }
}

define lvs::monitor_service_http_https ( $ip_address, $uri, $critical="true", $contact_group="admins" ) {
    # Virtual resource for the monitoring host
    @monitor_host { $title:
        ip_address => $ip_address,
        group => "lvs",
        critical => "true",
        contact_group => $contact_group
    }

    @monitor_service { $title:
        host => $title,
        group => "lvs",
        description => "LVS HTTP IPv4",
        check_command => "check_http_lvs!${uri}",
        critical => $critical
    }

    @monitor_service { "${title}_https":
        host => $title,
        group => "lvs",
        description => "LVS HTTPS IPv4",
        check_command => "check_https_url!${uri}",
        critical => $critical
    }
}

define lvs::monitor_service6_http_https ( $ip_address, $uri, $critical="true" ) {
    # Virtual resource for the monitoring host
    @monitor_host { "${title}_ipv6":
        ip_address => $ip_address,
        group => "lvs",
        critical => "true"
    }

    @monitor_service { "${title}_ipv6":
        host => "${title}_ipv6",
        group => "lvs",
        description => "LVS HTTP IPv6",
        check_command => "check_http_lvs!${uri}",
        critical => $critical
    }

    @monitor_service { "${title}_ipv6_https":
        host => "${title}_ipv6",
        group => "lvs",
        description => "LVS HTTPS IPv6",
        check_command => "check_https_url!${uri}",
        critical => $critical
    }
}
