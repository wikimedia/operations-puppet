class profile::dumps::fetcher {
    $publicdir = '/data/xmldatadumps/public'
    $otherdir = '/data/xmldatadumps/public/other'

    class {'dumps::web::fetches::kiwix':
        user      => 'datasets',
        group     => 'datasets',
        publicdir => $publicdir,
        otherdir  => $otherdir,
    }
    class {'dumps::web::fetches::stats':
        src      => 'stat1005.eqiad.wmnet::hdfs-archive',
        otherdir => $otherdir,
        user     => 'datasets',
    }
    class {'dumps::web::fetches::wikitech_dumps':
        url => 'https://wikitech.wikimedia.org/dumps/',
    }
}
