# SPDX-License-Identifier: Apache-2.0
# ldf endpoint monitoring, see T347355
class profile::query_service::monitor::ldf {
    prometheus::blackbox::check::http { 'query.wikidata.org-ldf':
        instance_label     => $facts['hostname'],
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
