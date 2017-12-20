class profile::dumps::generation::server::primary(
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

    class { '::dumps::generation::server::rsyncer':
        xmldumpsdir    => $xmldumpsdir,
        xmlremotedirs  => 'dumpsdata1002.eqiad.wmnet::data/xmldatadumps/public/,dataset1001.wikimedia.org::data/xmldatadumps/public/',
        miscdumpsdir   => $miscdatasetsdir,
        miscremotedirs => 'dumpsdata1002.eqiad.wmnet::data/otherdumps/,dataset1001.wikimedia.org::data/xmldatadumps/public/other/',
    }
}
