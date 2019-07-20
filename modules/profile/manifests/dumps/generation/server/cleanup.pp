class profile::dumps::generation::server::cleanup(
    $isreplica = lookup('profile::dumps::cleanup::isreplica'),
    $miscdumpsdir = lookup('profile::dumps::miscdumpsdir'),
    $xmldumpsdir = lookup('profile::dumps::xmldumpspublicdir'),
    $dumpstempdir = lookup('profile::dumps::dumpstempdir'),
) {
    class {'::dumps::web::cleanup':
        isreplica    => $isreplica,
        miscdumpsdir => $miscdumpsdir,
        xmldumpsdir  => $xmldumpsdir,
        dumpstempdir => $dumpstempdir,
        user         => 'dumpsgen',
    }
}
