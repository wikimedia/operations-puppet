# scripts for syncing apache changes
class apachesync {

    file { '/usr/local/bin/sync-apache':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/apachesync/sync-apache',
    }

    file { '/usr/local/bin/apache-graceful-all':
        owner => 'root',
        group => 'root',
        mode => '0555',
        source => 'puppet:///modules/apachesync/apache-graceful-all',
    }

    file { '/usr/local/bin/sync-apache-simulated':
        ensure => link,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        target => '/usr/local/bin/sync-apache',
    }

    file  { '/usr/local/bin/apache-fast-test':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/apachesync/apache-fast-test',
    }

}
