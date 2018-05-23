class profile::dumps::generation::server::jobswatcher(
    $xmldumpspublicdir  = hiera('profile::dumps::xmldumpspublicdir'),
    $xmldumpsprivatedir = hiera('profile::dumps::xmldumpsprivatedir'),
) {
    class {'::dumps::generation::server::jobswatcher':
        dumpsbasedir => $xmldumpspublicdir,
        locksbasedir => $xmldumpsprivatedir,
        user         => 'dumpsgen',
    }
}
