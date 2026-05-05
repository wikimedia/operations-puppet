# SPDX-License-Identifier: Apache-2.0
# Contains blackbox checks for miscweb services on Kubernetes (T300171)
class profile::microsites::monitoring {

    Prometheus::Blackbox::Check::Http {
        team                    => 'collaboration-services',
        severity                => 'task',
        path                    => '/',
        ip_families             => ['ip4'],
        force_tls               => true,
        status_matches          => [200],
        port                    => 30443, # Kubernetes Ingress port
        ip4                     => ipresolve('miscweb.discovery.wmnet', 4), # Kubernetes Ingress
        certificate_expiry_days => 9,
    }

    prometheus::blackbox::check::http { '15.wikipedia.org':
        body_regex_matches => ['Wikipedia 15'],
    }

    prometheus::blackbox::check::http { 'annual.wikimedia.org':
        path               => '/2017/',
    }

    prometheus::blackbox::check::http { 'bienvenida.wikimedia.org':
        body_regex_matches => ['enciclopedia'],
    }

    prometheus::blackbox::check::http { 'transparency.wikimedia.org':
        status_matches   => [302],
        follow_redirects => false,
    }

    prometheus::blackbox::check::http { 'transparency-archive.wikimedia.org':
        body_regex_matches => ['Transparency'],
    }

    prometheus::blackbox::check::http { 'tendril.wikimedia.org':
        body_regex_matches => ['retired'],
    }

    prometheus::blackbox::check::http { 'dbtree.wikimedia.org':
        body_regex_matches => ['retired'],
    }

    prometheus::blackbox::check::http { 'wikiworkshop.org':
        path               => '/2023/',
        body_regex_matches => ['Wiki Workshop'],
    }

    prometheus::blackbox::check::http { 'wikipedia25.org':
        path               => '/en',
        body_regex_matches => ['25 years of Wikipedia'],
    }

    prometheus::blackbox::check::http { 'research.wikimedia.org':
        body_regex_matches => ['Wikimedia Research'],
    }

    prometheus::blackbox::check::http { 'static-codereview.wikimedia.org':
        path               => '/MediaWiki/1.html',
        body_regex_matches => ['Code Review'],
    }

    prometheus::blackbox::check::http { 'design.wikimedia.org':
        body_regex_matches => ['Design'],
    }

    prometheus::blackbox::check::http { 'security.wikimedia.org':
        body_regex_matches => ['Wikimedia Security'],
    }

    prometheus::blackbox::check::http { 'status.wikimedia.org':
        body_regex_matches => ['wikimediastatus'],
    }
    prometheus::blackbox::check::http { 'query.wikidata.org':
        body_regex_matches => ['Wikidata_Query'],
    }

    prometheus::blackbox::check::http { 'os-reports.wikimedia.org':
        body_regex_matches => ['OS deprecation'],
        ip4                => ipresolve('os-reports.discovery.wmnet', 4), # Kubernetes Aux cluster Ingress
    }
}
