class download::cron-rsync-dumps {
        file { '/usr/local/bin/rsync-dumps.sh':
        mode   => '0755',
        owner  => root,
        group  => root,
        path   => '/usr/local/bin/rsync-dumps.sh',
        source => 'puppet:///modules/download/rsync-dumps.sh';
    }

    cron { 'rsync-dumps':
        ensure  => present,
        command => '/usr/local/bin/rsync-dumps.sh',
        user    => root,
        minute  => '0',
        hour    => '*/2',
        require => File['/usr/local/bin/rsync-dumps.sh'];
    }
}
