class dataset::cron::rsync::peers($enable=true) {
    include dataset::common

    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    file { '/usr/local/bin/rsync-dumps.sh':
        ensure => $ensure,
    }

    file { '/usr/local/bin/rsync-dumps.py':
        ensure => $ensure,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        path   => '/usr/local/bin/rsync-dumps.py',
        source => 'puppet:///modules/dataset/rsync-dumps.py',
    }

    cron { 'rsync-dumps':
        ensure  => $ensure,
        command => '/usr/bin/python /usr/local/bin/rsync-dumps.py',
        user    => 'root',
        minute  => '0',
        hour    => '*/2',
        require => File['/usr/local/bin/rsync-dumps.py'],
    }
}
