class profile::ci::publisher {

    require profile::labs::lvm::srv

    class { 'rsync::server': }

    file { '/srv/doc':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0775',
    }

    rsync::server::module { 'doc':
        path      => '/srv/doc',
        read_only => 'no',
        require   => [
            File['/srv/doc'],
        ],
    }

}
