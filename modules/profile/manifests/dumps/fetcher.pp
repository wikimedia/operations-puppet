class profile::dumps::fetcher(
    $xmldumpsdir = hiera('profile::dumps::xmldumpspublicdir'),
    $otherdir = hiera('profile::dumps::miscdumpsdir'),
) {
    class {'dumps::web::fetches::kiwix':
        user        => 'dumpsgen',
        group       => 'dumpsgen',
        xmldumpsdir => $xmldumpsdir,
        otherdir    => $otherdir,
    }
    class {'dumps::web::fetches::stats':
        src      => 'stat1005.eqiad.wmnet::hdfs-archive',
        otherdir => $otherdir,
        user     => 'dumpsgen',
    }
    class {'dumps::web::fetches::wikitech_dumps':
        url => 'https://wikitech.wikimedia.org/dumps/',
    }
}
