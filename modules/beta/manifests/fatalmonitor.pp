#Monitors beta fatals daily
class beta::fatalmonitor {
    file { '/usr/local/bin/monitor_fatals':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/beta/monitor_fatals.rb',
    }

    cron { 'beta_monitor_fatals_twice_per_days':
        require => File['/usr/local/bin/monitor_fatals'],
        command => '/usr/local/bin/monitor_fatals',
        user    => 'nobody',
        # Whenever changing the frequency please update the duration
        # in file/beta/files/monitor_fatals.rb
        minute  => '0',
        hour    => ['0','12'],
    }
}

