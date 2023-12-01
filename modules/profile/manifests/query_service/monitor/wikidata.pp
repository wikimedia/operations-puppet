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

    # ldf endpoint monitoring, see T347355
    prometheus::blackbox::check::http { 'query.wikidata.org-ldf':
        instance_label     => 'wdqs1015',
        server_name        => 'query.wikidata.org',
        team               => 'search-platform',
        severity           => 'task',
        path               => '/bigdata/ldf',
        body               => {
            'subject'   => 'wd:Q42',
            'predicate' => 'wdt:P31',
            'object'    => '',
        },
        body_regex_matches => ['wd:Q42  wdt:P31  wd:Q5 .'],
        force_tls          => true,
        ip4                => ipresolve('wdqs-ldf.discovery.wmnet'),
        ip_families        => [ip4],
    }
}

