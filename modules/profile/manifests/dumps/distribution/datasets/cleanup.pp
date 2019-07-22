class profile::dumps::distribution::datasets::cleanup(
    $isreplica = lookup('profile::dumps::distribution::datasets::cleanup::isreplica'),
    $miscdumpsdir = lookup('profile::dumps::distribution::miscdumpsdir'),
    $xmldumpsdir = lookup('profile::dumps::distribution::xmldumpspublicdir'),
    $dumpstempdir = lookup('profile::dumps::distribution::dumpstempdir'),
) {
    class {'::dumps::web::cleanup':
        isreplica    => $isreplica,
        miscdumpsdir => $miscdumpsdir,
        xmldumpsdir  => $xmldumpsdir,
        dumpstempdir => $dumpstempdir,
        user         => 'dumpsgen',
    }
}
