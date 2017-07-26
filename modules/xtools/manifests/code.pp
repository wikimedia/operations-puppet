class xtools::code {
    group { 'xtools':
        ensure => present,
    }

    user { 'xtools-update':
        ensure  => present,
        group   => 'xtools',
        system  => true,
        require => Group['xtools'],
    }

    file { '/srv/xtools':
        ensure => directory,
        owner  => 'xtools-update',
        mode   => '0775',
    }

    ::git::clone { 'xtools':
        directory => '/srv/xtools',
        owner     => 'xtools-update',
        origin    => 'https://github.com/x-tools/xtools-rebirth.git',
        require   => [ User['xtools-update'], File['/srv/xtools'] ]
    }
    # todo: composer install. Requires user input so far

    file { '/usr/local/update-xtools':
        source => 'xtools/update-xtools',
        owner  => 'root',
        mode   => '0555',
    }

    cron { 'update-xtools':
        ensure  => present,
        command => '/usr/local/update-xtools',
        user    => 'xtools-update',
        hour    => '*',
        require => [ File['/usr/local/update-xtools'], Git::Clone['xtools'] ],
    }
}
