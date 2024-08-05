# SPDX-License-Identifier: Apache-2.0
# Creates monitoring checks for
class profile::query_service::monitor::wikidata_scholarly {

    monitoring::service { 'WDQS_Scholarly_External_SPARQL_Endpoint':
        description   => 'WDQS Scholarly SPARQL',
        check_command => 'check_https_url_for_string!query-scholarly.wikidata.org!/bigdata/namespace/wdq/sparql?query=SELECT%20*%20WHERE%20%7Bwikibase%3ADump%20schema%3AdateModified%20%3Fy%7D%20LIMIT%201!http://www.w3.org/2001/XMLSchema#dateTime',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Wikidata_query_service/Runbook',
    }

    prometheus::blackbox::check::http { 'wdqs_scholarly_external_sparql_endpoint_sre':
        server_name        => 'query-scholarly.wikidata.org',
        instance_label     => $facts['hostname'],
        team               => 'data-platform',
        severity           => 'info',
        path               => '/bigdata/namespace/wdq/sparql?query=SELECT%20*%20WHERE%20%7Bwikibase%3ADump%20schema%3AdateModified%20%3Fy%7D%20LIMIT%201',
        body_regex_matches => ['http:\/\/www\.w3\.org\/2001\/XMLSchema#dateTime'],
        force_tls          => true,
        port               => 443,
        req_headers        => { 'Accept' => '*/*', 'User-Agent' => 'prometheus-scholarly-sparql-ep-check' },
        ip4                => $facts['ipaddress'],
        ip6                => $facts['ipaddress6'],
    }
    prometheus::blackbox::check::http { 'wdqs_scholarly_external_sparql_endpoint_search':
        server_name        => 'query-scholarly.wikidata.org',
        instance_label     => $facts['hostname'],
        team               => 'search-platform',
        severity           => 'info',
        path               => '/bigdata/namespace/wdq/sparql?query=SELECT%20*%20WHERE%20%7Bwikibase%3ADump%20schema%3AdateModified%20%3Fy%7D%20LIMIT%201',
        body_regex_matches => ['http:\/\/www\.w3\.org\/2001\/XMLSchema#dateTime'],
        force_tls          => true,
        port               => 443,
        req_headers        => { 'Accept' => '*/*', 'User-Agent' => 'prometheus-scholarly-sparql-ep-check' },
        ip4                => $facts['ipaddress'],
        ip6                => $facts['ipaddress6'],
    }
}
