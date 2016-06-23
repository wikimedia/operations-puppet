class sanitarium {
    file { '/usr/local/bin/generate_labs_table.sh':
        ensure => present,
        owner  => 'dbmaint',
        group  => 'dbmaint',
        mode   => '0700',
        source => 'puppet:///modules/db_maintenance/generate_labs_table.sh',
    }
    cron {
        requires => File['/usr/local/bin/generate_labs_table.sh'],
    }
}
