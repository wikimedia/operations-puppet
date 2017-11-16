class profile::dumps::generation::server::primary {
    class { '::dumpsuser': }

    class { '::dumps::generation::server::dirs':
        user  => $dumpsuser::user,
        group => $dumpsuser::group,
    }

    class { '::dumps::generation::server::rsyncer':
        dumpsdir   => '/data/xmldatadumps',
        remotedirs => 'dumpsdata1002.eqiad.wmnet::data/xmldatadumps/public/,dataset1001.wikimedia.org::data/xmldatadumps/public/,labstore1006.wikimedia.org::data/xmldatadumps/public/',
    }
}
