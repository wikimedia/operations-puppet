class dumps::copying::peers(
    $serverinfo = undef,
) {
    file { '/usr/local/bin/rsync-dumps.py':
        ensure => 'present',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        path   => '/usr/local/bin/rsync-dumps.py',
        source => 'puppet:///modules/dumps/copying/rsync-dumps.py',
    }

    cron { 'rsync-dumps':
        ensure  => 'present',
        # filter out error messages about vanishing files, we don't want email for that
        command => "/usr/bin/python /usr/local/bin/rsync-dumps.py --servers '$serverinfo' 2>&1 | grep -v vanished",
        user    => 'root',
        minute  => '0',
        hour    => '*/2',
        require => File['/usr/local/bin/rsync-dumps.py'],
    }
}
