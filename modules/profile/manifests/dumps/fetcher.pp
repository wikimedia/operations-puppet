class dumps::fetcher() {
    class {'dumps::fetches::kiwix':
        user  => 'datasets',
        group => 'datasets',
    }
    class {'dumps::fetches::stats':
        src      => 'stat1005.eqiad.wmnet::hdfs-archive',
        otherdir => '/data/xmldatadumps/public/other',
        user     => 'datasets',
    }
    class {'dumps::fetches::wikitech_dumps':
        url => 'https://wikitech.wikimedia.org/dumps/',
    }
}
