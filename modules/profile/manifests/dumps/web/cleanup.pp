class profile::dumps::web::cleanup(
    $isreplica = hiera('profile::dumps::cleanup::isreplica'),
    $miscdumpsdir = hiera('profile::dumps::miscdumpsdir'),
    $xmldumpsdir = hiera('profile::dumps::xmldumpspublicdir'),
    $dumpstempdir = hiera('profile::dumps::dumpstempdir'),
) {
    class {'::dumps::web::cleanup':
        isreplica    => $isreplica,
        miscdumpsdir => $miscdumpsdir,
        xmldumpsdir  => $xmldumpsdir,
        dumpstempdir => $dumpstempdir,
        user         => 'dumpsgen',
    }
}
