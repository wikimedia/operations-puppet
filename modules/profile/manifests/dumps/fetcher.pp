class profile::dumps::fetcher(
    $publicdir = hiera('profile::dumps::xmldumpspublicdir'),
    $otherdir = hiera('profile::dumps::miscdumpspublicdir'),
) {
    class {'dumps::web::fetches::kiwix':
        user      => 'dumpsgen',
        group     => 'dumpsgen',
        publicdir => $publicdir,
        otherdir  => $otherdir,
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
