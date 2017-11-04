class profile::dumps::generation::server_primary {
    class { '::dumpsuser': }

    class { '::dumps::generation::server::dirs':
        user  => $dumpsuser::user,
        group => $dumpsuser::group,
    }

    class { '::dumps::generation::server::rsyncer':
        dumpsdir   => '/data/xmldatadumps/public',
        remotedirs => 'dumpsdata1002.eqiad.wmnet::data/xmldatadumps/public/',
    }
}
