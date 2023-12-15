# SPDX-License-Identifier: Apache-2.0
class profile::query_service::monitor::ldf {
    prometheus::blackbox::check::http { 'query.wikidata.org-ldf':
        instance_label     => $facts['hostname'],
        server_name        => 'query.wikidata.org',
        team               => 'search-platform',
        severity           => 'task',
        path               => '/bigdata/ldf?subject=wd%3AQ42&predicate=wdt%3AP31&object=',
        body_regex_matches => ['wd:Q42\s+wdt:P31\s+wd:Q5\s+\.'],
        force_tls          => true,
        ip4                => $facts['ipaddress'],
        ip6                => $facts['ipaddress6'],
        port               => 443,
        useragent          => 'prometheus-ldf-check',
    }
}

