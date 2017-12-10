class profile::dumps::web::cleanup_miscdatasets(
    $miscdumpsdir = hiera('profile::dumps::miscdumpsdir'),
) {
    class {'::dumps::web::cleanups::miscdatasets':
        miscdumpsdir => $miscdumpsdir,
        user         => 'dumpsgen',
    }
}
