# SPDX-License-Identifier: Apache-2.0
define profile::query_service::monitor::sparql_endpoint (
    $server_name,
    $team,
) {
    prometheus::blackbox::check::http { "${title}_sparql_endpoint":
        server_name        => $server_name,
        instance_label     => $facts['hostname'],
        team               => $team,
        severity           => 'info',
        path               => '/bigdata/namespace/wdq/sparql?query=SELECT%20*%20WHERE%20%7Bwikibase%3ADump%20schema%3AdateModified%20%3Fy%7D%20LIMIT%201',
        body_regex_matches => ['http:\/\/www\.w3\.org\/2001\/XMLSchema#dateTime'],
        force_tls          => true,
        port               => 443,
        req_headers        => { 'Accept' => '*/*', 'User-Agent' => 'prometheus-sparql-check' },
        ip4                => $facts['ipaddress'],
        ip6                => $facts['ipaddress6'],
        alert_after        => '8m',
    }
}