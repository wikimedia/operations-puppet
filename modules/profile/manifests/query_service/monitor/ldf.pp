# SPDX-License-Identifier: Apache-2.0
# ldf endpoint monitoring, see T347355.
# Temporarily set to http instead of https until we can figure out
# some routing issues between prometheus and wdqs envoy

class profile::query_service::monitor::ldf {
    prometheus::blackbox::check::http { 'query.wikidata.org-ldf':
        instance_label => $facts['hostname'],
        server_name    => 'query.wikidata.org',
        team           => 'search-platform',
        severity       => 'task',
        path           => '/bigdata/ldf',
        force_tls      => false,
        ip4            => $facts['ipaddress'],
        ip6            => $facts['ipaddress6'],
        port           => 80,
        useragent      => 'prometheus-ldf-check',
    }
}
