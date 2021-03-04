# Wikidata Query Service UI (T266702)
class profile::microsites::wdqs {

    httpd::site { 'query.wikidata.org':
        content => template('profile/wdqs/httpd-query.wikidata.org.erb'),
    }

    httpd::site { 'query-preview.wikidata.org':
        content => template('profile/wdqs/httpd-query-preview.wikidata.org.erb'),
    }

    ensure_resource('file', '/srv/org', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikidata', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikidata/query', {'ensure' => 'directory' })

    git::clone { 'wikidata/query/gui-deploy':
        ensure    => 'latest',
        source    => 'gerrit',
        directory => '/srv/org/wikidata/query',
        branch    => 'production',
    }
}
