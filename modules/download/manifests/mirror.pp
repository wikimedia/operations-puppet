class download::mirror {
    system::role { 'download::mirror': description => 'Service for rsync to external download mirrors' }

    include role::mirror::common

    file { '/etc/rsyncd.conf':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/download/rsync/rsyncd.conf.downloadmirror',
        require => Package['rsync'],
    }

    file { '/etc/default/rsync':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/download/rsync/rsync.default.downloadmirror',
        require => Package['rsync'],
    }

    service { 'rsync':
        ensure  => running,
        require => [ Package['rsync'], File['/etc/rsyncd.conf'],File['/etc/default/rsync'] ],
    }
}
