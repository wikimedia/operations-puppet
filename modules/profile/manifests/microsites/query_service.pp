# SPDX-License-Identifier: Apache-2.0
# Wikibase Query Service UI (T266702)
class profile::microsites::query_service {

    profile::microsites::query_service::site { 'wdqs':
        domain_name => 'query.wikidata.org',
    }

    profile::microsites::query_service::site { 'wdqs-preview':
        domain_name => 'query-preview.wikidata.org',
        deploy_name => 'wdqs',
    }

    profile::microsites::query_service::site { 'wcqs':
        domain_name => 'commons-query.wikimedia.org',
    }

    wmflib::dir::mkdir_p('/srv/org/wikidata/query')
    wmflib::dir::mkdir_p('/srv/org/wikidata/query-builder')

    git::clone { 'wikidata/query/gui-deploy':
        ensure    => 'latest',
        source    => 'gerrit',
        directory => '/srv/org/wikidata/query',
        branch    => 'production',
    }

    git::clone { 'wikidata/query-builder/deploy':
        ensure    => 'latest',
        source    => 'gerrit',
        directory => '/srv/org/wikidata/query-builder',
        branch    => 'production',
    }
}
