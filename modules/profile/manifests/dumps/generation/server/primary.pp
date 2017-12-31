class profile::dumps::generation::server::primary {
    require profile::dumps::generation::server::common

    class { '::dumps::generation::server::rsyncer':
        xmldumpsdir    => $profile::dumps::generation::server::common::xmldumpsdir,
        xmlremotedirs  => 'dumpsdata1002.eqiad.wmnet::data/xmldatadumps/public/,dataset1001.wikimedia.org::data/xmldatadumps/public/,labstore1006.wikimedia.org::data/xmldatadumps/public/',
        miscdumpsdir   =>  $profile::dumps::generation::server::common::miscdatasetsdir,
        miscremotedirs => 'dumpsdata1002.eqiad.wmnet::data/otherdumps/,dataset1001.wikimedia.org::data/xmldatadumps/public/other/,labstore1006.wikimedia.org::data/xmldatadumps/public/other/',
    }
}
