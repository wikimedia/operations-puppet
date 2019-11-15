class profile::dumps::generation::server::primary {
    require profile::dumps::generation::server::common

    class { '::dumps::generation::server::rsyncer':
        xmldumpsdir    => $profile::dumps::generation::server::common::xmldumpsdir,
        xmlremotedirs  => 'dumpsdata1003.eqiad.wmnet::data/xmldatadumps/public/,labstore1006.wikimedia.org::data/xmldatadumps/public/,labstore1007.wikimedia.org::data/xmldatadumps/public/',
        miscdumpsdir   => $profile::dumps::generation::server::common::miscdatasetsdir,
        miscremotedirs => 'dumpsdata1003.eqiad.wmnet::data/otherdumps/,labstore1006.wikimedia.org::data/xmldatadumps/public/other/,labstore1007.wikimedia.org::data/xmldatadumps/public/other/',
    }
}
