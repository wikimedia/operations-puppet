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
        path               => '/readiness-probe',
        body_regex_matches => ['xmlns'],
        force_tls          => true,
        port               => 443,
        req_headers        => { 'Accept' => '*/*', 'User-Agent' => 'prometheus-sparql-check' },
        ip4                => $facts['ipaddress'],
        ip6                => $facts['ipaddress6'],
        # WDQS servers are depooled when overloaded and they tend to recover
        # after a while. We only want to be alerted for prolonged issues.
        # This is in agreement with WDQS SLOs, which are quite lax.
        # See: https://wikitech.wikimedia.org/wiki/SLO/WDQS
        alert_after        => '2h',
    }
}