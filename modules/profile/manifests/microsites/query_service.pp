# SPDX-License-Identifier: Apache-2.0
# Wikibase Query Service UI (T266702)
class profile::microsites::query_service {

    profile::microsites::query_service::site { 'wdqs':
        domain_name => 'query.wikidata.org',
    }

    profile::microsites::query_service::site { 'wcqs':
        domain_name => 'commons-query.wikimedia.org',
    }

    wmflib::dir::mkdir_p('/srv/org/wikidata/query')
    wmflib::dir::mkdir_p('/srv/org/wikidata/query-builder')

    git::clone { 'wikidata/query/gui-deploy':
        ensure    => latest,
        source    => 'gerrit',
        directory => '/srv/org/wikidata/query',
        branch    => 'production',
    }

    git::clone { 'wikidata/query-builder/deploy':
        ensure    => latest,
        source    => 'gerrit',
        directory => '/srv/org/wikidata/query-builder',
        branch    => 'production',
    }

    prometheus::blackbox::check::http { 'commons-query.wikimedia.org':
        team        => 'serviceops-collab',
        severity    => 'task',
        path        => '/',
        force_tls   => false,
        port        => 80,
        ip_families => [ip4],
    }

    prometheus::blackbox::check::http { 'query.wikidata.org':
        server_name => 'query.wikidata.org',
        team        => 'serviceops-collab',
        severity    => 'task',
        path        => '/',
        force_tls   => true,
        ip_families => [ip4],
    }
    prometheus::blackbox::check::http { 'query.wikidata.org-ldf':
        server_name        => 'query.wikidata.org',
        team               => 'search-platform',
        severity           => 'task',
        path               => '/bigdata/ldf',
        body               => {
            'subject'   => 'wd:42',
            'predicate' => 'wdt:P31',
            'object'    => '',
        },
        body_regex_matches => ['wd:Q42  wdt:P31  wd:Q5 .'],
        force_tls          => true,
        # wdqs1015 is the only host for the LDF endpoint, see hieradata/common/profile/trafficserver/backend.yaml
        ip4                => ipresolve('wdqs1015.eqiad.wmnet', 4),
        ip_families        => [ip4],
    }
}
