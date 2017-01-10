# ganglia views for DNS servers
class ganglia::views::dns {
    $auth_dns_host_regex = '^(radon|baham|eeden)\.'
    $rec_dns_host_regex = '^(chromium|hydrogen|acamar|achernar|maerlant|nescio)\.'

    ganglia::web::view { 'authoritative_dns':
        ensure      => 'present',
        description => 'DNS Authoritative',
        graphs      => [
            {
            'title'        => 'DNS UDP Requests',
            'host_regex'   => $auth_dns_host_regex,
            'metric_regex' => '^gdnsd_udp_reqs$',
            'type'         => 'stack',
            },
            {
            'title'        => 'DNS TCP Requests',
            'host_regex'   => $auth_dns_host_regex,
            'metric_regex' => '^gdnsd_tcp_reqs$',
            'type'         => 'stack',
            },
            {
            'title'        => 'DNS NXDOMAIN',
            'host_regex'   => $auth_dns_host_regex,
            'metric_regex' => '^gdnsd_stats_nxdomain$',
            'type'         => 'stack',
            },
            {
            'title'        => 'DNS REFUSED',
            'host_regex'   => $auth_dns_host_regex,
            'metric_regex' => '^gdnsd_stats_refused$',
            'type'         => 'stack',
            },
            {
            'title'        => 'DNS queries over IPv6',
            'host_regex'   => $auth_dns_host_regex,
            'metric_regex' => '^gdnsd_stats_v6$',
            'type'         => 'stack',
            },
            {
            'title'        => 'DNS EDNS Client Subnet requests',
            'host_regex'   => $auth_dns_host_regex,
            'metric_regex' => '^gdnsd_stats_edns_clientsub$',
            'type'         => 'stack',
            },
        ],
    }

    ganglia::web::view { 'recursive_dns':
        ensure      => 'present',
        description => 'DNS Recursive',
        graphs      => [
            {
            'title'        => 'DNS Outgoing queries',
            'host_regex'   => $rec_dns_host_regex,
            'metric_regex' => '^pdns_all-outqueries$',
            'type'         => 'stack',
            },
            {
            'title'        => 'DNS Answers',
            'host_regex'   => $rec_dns_host_regex,
            'metric_regex' => '^pdns_answers.*$',
            'type'         => 'stack',
            },
            {
            'title'        => 'DNS cache',
            'host_regex'   => $rec_dns_host_regex,
            'metric_regex' => '^pdns_cache-.*$',
            'type'         => 'stack',
            },
            {
            'title'        => 'DNS IPv6 Outgoing queries',
            'host_regex'   => $rec_dns_host_regex,
            'metric_regex' => '^pdns_ipv6-outqueries$',
            'type'         => 'stack',
            },
            {
            'title'        => 'DNS Incoming queries',
            'host_regex'   => $rec_dns_host_regex,
            'metric_regex' => '^pdns_questions$',
            'type'         => 'stack',
            },
            {
            'title'        => 'DNS Servfails',
            'host_regex'   => $rec_dns_host_regex,
            'metric_regex' => '^pdns_servfail-asnwers$',
            'type'         => 'stack',
            },
            {
            'title'        => 'DNS NXDOMAIN',
            'host_regex'   => $rec_dns_host_regex,
            'metric_regex' => '^pdns_nxdomain-asnwers$',
            'type'         => 'stack',
            },
        ],
    }
}

