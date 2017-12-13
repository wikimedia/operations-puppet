class profile::dumps::fetcher(
    $xmldumpsdir = hiera('profile::dumps::xmldumpspublicdir'),
    $miscdatasetsdir = hiera('profile::dumps::miscdumpsdir'),
) {
    class {'dumps::web::fetches::kiwix':
        user            => 'dumpsgen',
        group           => 'dumpsgen',
        xmldumpsdir     => $xmldumpsdir,
        miscdatasetsdir => $miscdatasetsdir,
    }
    class {'dumps::web::fetches::stats':
        src             => 'stat1005.eqiad.wmnet::hdfs-archive',
        miscdatasetsdir => $miscdatasetsdir,
        user            => 'dumpsgen',
    }
    class {'dumps::web::fetches::wikitech_dumps':
        url             => 'https://wikitech.wikimedia.org/dumps/',
        miscdatasetsdir => $miscdatasetsdir,
    }
}
