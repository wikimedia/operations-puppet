# This is for the alerting host to monitor the shared public addrs
class profile::dns::auth::monitoring::global (
    Hash[String, Hash[String, String]] $authdns_addrs = lookup('authdns_addrs'),
) {
    $authdns_addrs.each |$label,$data| {
        @monitoring::host { $label:
            ip_address => $data['address'],
        }
        @monitoring::service { $label:
            host          => $label,
            description   => 'Auth DNS',
            check_command => 'check_dns_query_auth!www.wikipedia.org',
            critical      => true,
            notes_url     => 'https://wikitech.wikimedia.org/wiki/DNS',
        }
    }
}
