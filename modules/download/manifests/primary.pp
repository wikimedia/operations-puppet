class download::primary {

    system::role { 'download::primary': description => 'Service for rsync to internal download mirrors' }

        include role::mirror::common

    file {
        '/etc/rsyncd.conf':
            require => Package[rsync],
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            source  => 'puppet:///files/rsync/rsyncd.conf.downloadprimary';
        '/etc/default/rsync':
            require => Package[rsync],
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            source  => 'puppet:///files/rsync/rsync.default.downloadprimary';
    }

    service { 'rsync':
        ensure  => running,
        require => [ Package[rsync], File['/etc/rsyncd.conf'], File['/etc/default/rsync'] ];
    }
}

