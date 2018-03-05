class profile::dumps::distribution::datasets::cleanup(
    $isreplica = hiera('profile::dumps::distribution::datasets::cleanup::isreplica'),
    $labscopy = hiera('profile::dumps::::distribution::datasets::cleanup::labscopy'),
    $miscdumpsdir = hiera('profile::dumps::distribution::miscdumpsdir'),
    $xmldumpsdir = hiera('profile::dumps::distribution::xmldumpspublicdir'),
    $dumpstempdir = hiera('profile::dumps::distribution::dumpstempdir'),
) {
    class {'::dumps::web::cleanup':
        isreplica    => $isreplica,
        labscopy     => $labscopy,
        miscdumpsdir => $miscdumpsdir,
        xmldumpsdir  => $xmldumpsdir,
        dumpstempdir => $dumpstempdir,
        user         => 'dumpsgen',
    }
}
