# SPDX-License-Identifier: Apache-2.0
# Monitor exteral blazegraph settings for the wikidata.org dataset
class profile::query_service::monitor::wikidata {
    nrpe::monitor_service { 'Query_Service_Internal_HTTP_endpoint':
        description  => 'Query Service HTTP Port',
        nrpe_command => '/usr/lib/nagios/plugins/check_http -H 127.0.0.1 -p 80 -w 10 -u /readiness-probe',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Wikidata_query_service',
    }

    monitoring::service { 'WDQS_External_SPARQL_Endpoint':
        description   => 'WDQS SPARQL',
        check_command => 'check_https_url_for_string!query.wikidata.org!/bigdata/namespace/wdq/sparql?query=SELECT%20*%20WHERE%20%7Bwikibase%3ADump%20schema%3AdateModified%20%3Fy%7D%20LIMIT%201!http://www.w3.org/2001/XMLSchema#dateTime',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Wikidata_query_service/Runbook',
    }

    prometheus::blackbox::check::http { 'wdqs_external_sparql_endpoint_sre':
        server_name        => 'query.wikidata.org',
        instance_label     => $facts['hostname'],
        team               => 'data-platform',
        severity           => 'info',
        path               => '/bigdata/namespace/wdq/sparql?query=SELECT%20*%20WHERE%20%7Bwikibase%3ADump%20schema%3AdateModified%20%3Fy%7D%20LIMIT%201',
        body_regex_matches => ['^http:\/\/www\.w3\.org\/2001\/XMLSchema#dateTime$'],
        force_tls          => true,
        port               => 443,
        req_headers        => { 'Accept' => '*/*', 'User-Agent' => 'prometheus-sparql-ep-check' },
        ip4                => $facts['ipaddress'],
        ip6                => $facts['ipaddress6'],
    }
    prometheus::blackbox::check::http { 'wdqs_external_sparql_endpoint_search':
        server_name        => 'query.wikidata.org',
        instance_label     => $facts['hostname'],
        team               => 'search-platform',
        severity           => 'info',
        path               => '/bigdata/namespace/wdq/sparql?query=SELECT%20*%20WHERE%20%7Bwikibase%3ADump%20schema%3AdateModified%20%3Fy%7D%20LIMIT%201',
        body_regex_matches => ['^http:\/\/www\.w3\.org\/2001\/XMLSchema#dateTime$'],
        force_tls          => true,
        port               => 443,
        req_headers        => { 'Accept' => '*/*', 'User-Agent' => 'prometheus-sparql-ep-check' },
        ip4                => $facts['ipaddress'],
        ip6                => $facts['ipaddress6'],
    }
}
