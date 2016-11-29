class role::mariadb::otrsbackups {
    include role::backup::host

    file { '/srv/backups':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0600', # implicitly 0700 for dirs
    }

    file { '/usr/local/bin/dumps-otrs.sh':
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => template('mariadb/dumps-otrs.sh.erb'),
    }

    cron { 'otrsbackups':
        minute   => '0',
        hour     => '0',
        monthday => '*',
        month    => '*',
        weekday  => '3',
        command  => '/usr/local/bin/dumps-otrs.sh > /srv/backups/dump.log 2>&1',
        user     => 'root',
        require  => [
            File['/usr/local/bin/dumps-otrs.sh'],
            File['/srv/backups'],
        ],
    }

    backup::set {'otrsdb': }
}
