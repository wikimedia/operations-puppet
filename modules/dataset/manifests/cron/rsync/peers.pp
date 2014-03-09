class dataset::cron::rsync::peers($enable=true) {
    include role::mirror::common

    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    file { '/usr/local/bin/rsync-dumps.sh':
        ensure => $ensure,
        mode   => '0755',
        owner  => root,
        group  => root,
        path   => '/usr/local/bin/rsync-dumps.sh',
        source => 'puppet:///modules/dataset/rsync-dumps.sh',
    }

    cron { 'rsync-dumps':
        ensure  => $ensure,
        command => '/usr/local/bin/rsync-dumps.sh',
        user    => root,
        minute  => '0',
        hour    => '*/2',
        require => File['/usr/local/bin/rsync-dumps.sh'],
    }
}
