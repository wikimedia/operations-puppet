class profile::dumps::generation::server::common(
    $datadir = lookup('profile::dumps::basedatadir'),
    $xmldumpsdir = lookup('profile::dumps::xmldumpspublicdir'),
    $miscdatasetsdir = lookup('profile::dumps::miscdumpsdir'),
    $dumpstempdir = lookup('profile::dumps::dumpstempdir'),
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
