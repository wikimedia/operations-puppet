# icinga monitoring for DNS recursors
define dnsrecursor::monitor() {
    # Monitoring
    monitoring::host { $title:
        ip_address => $title,
        parents    => $facts['networking']['hostname'],
    }
    monitoring::service { "recursive dns ${title}":
        host           => $title,
        description    => 'Recursive DNS',
        check_command  => 'check_dns_query!www.wikipedia.org',
        notes_url      => 'https://wikitech.wikimedia.org/wiki/DNS',
        migration_task => 'T384425',
    }
}
