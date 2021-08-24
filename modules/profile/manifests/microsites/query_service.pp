# Wikibase Query Service UI (T266702)
class profile::microsites::query_service {

    profile::microsites::query_service::site { 'wdqs':
        domain_name => 'query.wikidata.org',
    }

    profile::microsites::query_service::site { 'wdqs-preview':
        domain_name => 'query-preview.wikidata.org',
        deploy_name => 'wdqs',
    }

    ensure_resource('file', '/srv/org', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikidata', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikidata/query', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikidata/query-builder', {'ensure' => 'directory' })

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
