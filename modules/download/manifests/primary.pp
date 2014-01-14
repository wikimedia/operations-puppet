class download::primary {
    system::role { 'download::primary': description => 'Service for rsync to internal download mirrors' }

    include role::mirror::common

    file { '/etc/rsyncd.conf':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/download/rsync/rsyncd.conf.downloadprimary',
        require => Package['rsync'],
    }

    file { '/etc/default/rsync':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/download/rsync/rsync.default.downloadprimary',
        require => Package['rsync'],
    }

    service { 'rsync':
        ensure  => running,
        require => [ Package['rsync'], File['/etc/rsyncd.conf'],File['/etc/default/rsync'] ],
    }
}
