class beta::syncsiteresources {
    file { '/usr/local/bin/sync-site-resources':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/beta/sync-site-resources',
    }

    cron { 'sync-site-resources':
        ensure  => present,
        command => '/usr/local/bin/sync-site-resources >/dev/null 2>&1',
        require => File['/usr/local/bin/sync-site-resources'],
        hour    => '12',
        user    => 'apache',
    }
}

