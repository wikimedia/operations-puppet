class download::mirror {

    system::role { 'download::mirror': description => 'Service for rsync to external download mirrors' }

    include role::mirror::common

    file {
        '/etc/rsyncd.conf':
            require => Package[rsync],
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            source  => 'puppet:///files/rsync/rsyncd.conf.downloadmirror';
        '/etc/default/rsync':
            require => Package[rsync],
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            source  => 'puppet:///files/rsync/rsync.default.downloadmirror';
    }

    service { 'rsync':
        ensure  => running,
        require => [ Package[rsync], File['/etc/rsyncd.conf'], File['/etc/default/rsync'] ];
    }
}

