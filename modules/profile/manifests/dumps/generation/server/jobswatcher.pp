class profile::dumps::generation::server::jobswatcher(
    $xmldumpspublicdir  = lookup('profile::dumps::xmldumpspublicdir'),
    $xmldumpsprivatedir = lookup('profile::dumps::xmldumpsprivatedir'),
) {
    class {'::dumps::generation::server::jobswatcher':
        dumpsbasedir => $xmldumpspublicdir,
        locksbasedir => $xmldumpsprivatedir,
        user         => 'dumpsgen',
    }
}
