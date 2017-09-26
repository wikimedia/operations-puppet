class profile::dumps::fetcher {
    class {'dumps::web::fetches::kiwix':}
    class {'dumps::web::fetches::stats':
        src      => 'stat1005.eqiad.wmnet::hdfs-archive',
        otherdir => '/data/xmldatadumps/public/other',
    }
    class {'dumps::web::fetches::wikitech_dumps':
        url => 'https://wikitech.wikimedia.org/dumps/',
    }
}
