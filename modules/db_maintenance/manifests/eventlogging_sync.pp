class db_maintenance::eventlogging_sync {
    # FIXME: we need a systemd unit
    file { '/usr/local/bin/eventlogging_sync.sh':
        ensure => present,
        owner  => 'dbmaint', 
        group  => 'dbmaint',
        mode   => '0700',
        source => 'puppet:///modules/db_maintenance/eventlogging_sync.sh',
    }
    file { '/etc/init.d/eventlogging_sync':
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/db_maintenance/eventlogging_sync.init',
        require => File['/usr/local/bin/eventlogging_sync.sh'],
        notify  => Service['eventlogging_sync'],
    }

    service { 'eventlogging_sync':
        ensure => running,
        enable => true,
    }
    nrpe::monitor_service { 'eventlogging_sync':
        description   => 'eventlogging_sync processes',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:2 -u root -a "/bin/bash /usr/local/bin/eventlogging_sync.sh"',
        critical      => false,
        contact_group => 'admins', # show on icinga/irc only
    }
}
