# scripts for syncing apache changes
class apachesync {

    $scriptpath = '/usr/local/bin'

    file { "${scriptpath}/sync-apache":
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/apachesync/sync-apache',
    }

    file { "${scriptpath}/sync-apache-simulated":
        ensure => link,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        target => "${scriptpath}/sync-apache",
    }

    file { "${scriptpath}/apache-graceful-all":
        owner  => 'root',
        group  => 'root',
        mode   => '0554',
        source => 'puppet:///modules/apachesync/apache-graceful-all',
    }

    file  { "${scriptpath}/apache-fast-test":
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/apachesync/apache-fast-test',
    }

}
