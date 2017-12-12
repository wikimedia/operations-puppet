class profile::dumps::generation::server::fallback {
    class { '::dumpsuser': }

    class { '::dumps::generation::server::dirs':
        datadir     => '/data/xmldatadumps',
        xmldumpsdir => '/data/xmldatadumps/public',
        tempdir     => '/data/xmldatadumps/temp',
        otherdir    => '/data/otherdumps',
        user        => $dumpsuser::user,
        group       => $dumpsuser::group,
    }
}
