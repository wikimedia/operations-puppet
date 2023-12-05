# SPDX-License-Identifier: Apache-2.0
# ldf endpoint monitoring, see T347355.
# Temporarily set to http instead of https until we can figure out
# some routing issues between prometheus and wdqs envoy

class profile::query_service::monitor::ldf {
    prometheus::blackbox::check::http { 'query.wikidata.org-ldf':
        instance_label     => $facts['hostname'],
        server_name        => 'query.wikidata.org',
        team               => 'search-platform',
        severity           => 'email',
        path               => '/bigdata/ldf',
        body               => {
            'subject'   => 'wd:Q42',
            'predicate' => 'wdt:P31',
            'object'    => '',
        },
        body_regex_matches => ['wd:Q42\s+wdt:P31\s+wd:Q5\s+\.'],
        force_tls          => false,
        ip4                => ipresolve($facts['fqdn']),
        ip6                => ipresolve($facts['fdqn'], 6),
        port               => 80,
        useragent          => 'prometheus-ldf-check',
    }
}
