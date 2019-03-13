define lvs::monitor_service_http_https (
    $ip_address,
    $ip6_address   = undef,
    $uri           = undef,
    $check_command = undef,
    $critical      = true,
    $contact_group = 'admins'
) {
    # Virtual resource for the monitoring host
    @monitoring::host { $title:
        ip_address    => $ip_address,
        group         => 'lvs',
        critical      => true,
        contact_group => $contact_group,
    }

    if $check_command {
        @monitoring::service { $title:
            host          => $title,
            group         => 'lvs',
            description   => 'LVS HTTP IPv4',
            check_command => $check_command,
            critical      => $critical,
            contact_group => $contact_group,
            notes_url     => 'https://wikitech.wikimedia.org/wiki/LVS#Diagnosing_problems',
        }
    } else {
        @monitoring::service { $title:
            host          => $title,
            group         => 'lvs',
            description   => 'LVS HTTP IPv4',
            check_command => "check_http_lvs!${uri}",
            critical      => $critical,
            contact_group => $contact_group,
            notes_url     => 'https://wikitech.wikimedia.org/wiki/LVS#Diagnosing_problems',
        }

        @monitoring::service { "${title}_https":
            host          => $title,
            group         => 'lvs',
            description   => 'LVS HTTPS IPv4',
            check_command => "check_https_url!${uri}",
            critical      => $critical,
            contact_group => $contact_group,
            notes_url     => 'https://wikitech.wikimedia.org/wiki/LVS#Diagnosing_problems',
        }
    }
    if $ip6_address {
        @monitoring::host { "${title}_ipv6":
            ip_address    => $ip6_address,
            group         => 'lvs',
            critical      => true,
            contact_group => $contact_group,
        }
        if $check_command {
            @monitoring::service { "${title}_ipv6":
                host          => "${title}_ipv6",
                group         => 'lvs',
                description   => 'LVS HTTP IPv6',
                check_command => $check_command,
                critical      => $critical,
                contact_group => $contact_group,
                notes_url     => 'https://wikitech.wikimedia.org/wiki/LVS#Diagnosing_problems',
            }
        } else {
            @monitoring::service { "${title}_ipv6":
                host          => "${title}_ipv6",
                group         => 'lvs',
                description   => 'LVS HTTP IPv6',
                check_command => "check_http_lvs!${uri}",
                critical      => $critical,
                contact_group => $contact_group,
                notes_url     => 'https://wikitech.wikimedia.org/wiki/LVS#Diagnosing_problems',
            }

            @monitoring::service { "${title}_ipv6_https":
                host          => "${title}_ipv6",
                group         => 'lvs',
                description   => 'LVS HTTPS IPv6',
                check_command => "check_https_url!${uri}",
                critical      => $critical,
                contact_group => $contact_group,
                notes_url     => 'https://wikitech.wikimedia.org/wiki/LVS#Diagnosing_problems',
            }
        }
    }
}
