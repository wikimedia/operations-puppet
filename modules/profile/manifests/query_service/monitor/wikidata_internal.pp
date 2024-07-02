# SPDX-License-Identifier: Apache-2.0
class profile::query_service::monitor::wikidata_internal {
    nrpe::monitor_service { 'Query_Service_Internal_HTTP_endpoint':
        description  => 'Query Service HTTP Port',
        nrpe_command => '/usr/lib/nagios/plugins/check_http -H 127.0.0.1 -p 80 -w 10 -u /readiness-probe',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Wikidata_query_service',
    }

    prometheus::blackbox::check::http { 'wdqs_internal_sparql_endpoint_sre':
        server_name        => 'wdqs-internal.discovery.wmnet',
        instance_label     => $facts['hostname'],
        team               => 'data-platform',
        severity           => 'info',
        path               => '/bigdata/namespace/wdq/sparql?query=SELECT%20*%20WHERE%20%7Bwikibase%3ADump%20schema%3AdateModified%20%3Fy%7D%20LIMIT%201',
        body_regex_matches => ['http:\/\/www\.w3\.org\/2001\/XMLSchema#dateTime'],
        force_tls          => true,
        port               => 443,
        req_headers        => { 'Accept' => '*/*', 'User-Agent' => 'prometheus-internal-sparql-ep-check' },
        ip4                => $facts['ipaddress'],
        ip6                => $facts['ipaddress6'],
        alert_after        => '8m',
    }
    prometheus::blackbox::check::http { 'wdqs_internal_sparql_endpoint_search':
        server_name        => 'wdqs-internal.discovery.wmnet',
        instance_label     => $facts['hostname'],
        team               => 'search-platform',
        severity           => 'info',
        path               => '/bigdata/namespace/wdq/sparql?query=SELECT%20*%20WHERE%20%7Bwikibase%3ADump%20schema%3AdateModified%20%3Fy%7D%20LIMIT%201',
        body_regex_matches => ['http:\/\/www\.w3\.org\/2001\/XMLSchema#dateTime'],
        force_tls          => true,
        port               => 443,
        req_headers        => { 'Accept' => '*/*', 'User-Agent' => 'prometheus-internal-sparql-ep-check' },
        ip4                => $facts['ipaddress'],
        ip6                => $facts['ipaddress6'],
        alert_after        => '8m',
    }
}
