class profile::dumps::generation::server::common(
    $datadir = hiera('profile::dumps::basedatadir'),
    $xmldumpsdir = hiera('profile::dumps::xmldumpspublicdir'),
    $miscdatasetsdir = hiera('profile::dumps::miscdumpsdir'),
    $dumpstempdir = hiera('profile::dumps::dumpstempdir'),
) {
    class { '::dumpsuser': }

    class { '::dumps::generation::server::dirs':
        datadir         => $datadir,
        xmldumpsdir     => $xmldumpsdir,
        tempdir         => $dumpstempdir,
        miscdatasetsdir => $miscdatasetsdir,
        user            => $dumpsuser::user,
        group           => $dumpsuser::group,
    }
}
