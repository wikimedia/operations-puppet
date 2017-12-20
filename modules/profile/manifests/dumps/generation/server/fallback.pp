class profile::dumps::generation::server::fallback(
    $xmldumpsdir = hiera('profile::dumps::xmldumpspublicdir'),
    $miscdatasetsdir = hiera('profile::dumps::miscdumpsdir'),
    $dumpstempdir = hiera('profile::dumps::dumpstempdir'),
) {
    class { '::dumpsuser': }

    class { '::dumps::generation::server::dirs':
        datadir         => '/data/xmldatadumps',
        xmldumpsdir     => $xmldumpsdir,
        tempdir         => $dumpstempdir,
        miscdatasetsdir => $miscdatasetsdir,
        user            => $dumpsuser::user,
        group           => $dumpsuser::group,
    }
}
