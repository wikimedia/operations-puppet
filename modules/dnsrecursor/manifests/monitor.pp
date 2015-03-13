define dnsrecursor::monitor() {
    # Monitoring
    monitoring::host { $title:
        ip_address => $title,
    }
    monitoring::service { "recursive dns ${title}":
        host          => $title,
        description   => 'Recursive DNS',
        check_command => 'check_dns!www.wikipedia.org',
    }
}
