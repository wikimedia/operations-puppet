class profile::dumps::web::cleanup(
    $isreplica = hiera('profile::dumps::cleanup::isreplica'),
    $miscdumpsdir = hiera('profile::dumps::miscdumpsdir'),
) {
    class {'::dumps::web::cleanup':
        isreplica    => $isreplica,
        miscdumpsdir => $miscdumpsdir,
    }
}
