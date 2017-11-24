class profile::dumps::web::cleanup(
    $isreplica = hiera('profile::dumps::cleanup::isreplica'),
) {
    class {'::dumps::web::cleanup':
        isreplica => $isreplica,
    }
}
