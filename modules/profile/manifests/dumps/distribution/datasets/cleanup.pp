class profile::dumps::distribution::datasets::cleanup(
    $isreplica = hiera('profile::dumps::distribution::datasets::cleanup::isreplica'),
    $miscdumpsdir = hiera('profile::dumps::distribution::miscdumpsdir'),
    $xmldumpsdir = hiera('profile::dumps::distribution::xmldumpspublicdir'),
    $dumpstempdir = hiera('profile::dumps::distribution::dumpstempdir'),
) {
    class {'::dumps::web::cleanup':
        isreplica    => $isreplica,
        miscdumpsdir => $miscdumpsdir,
        xmldumpsdir  => $xmldumpsdir,
        dumpstempdir => $dumpstempdir,
        user         => 'dumpsgen',
    }
}
