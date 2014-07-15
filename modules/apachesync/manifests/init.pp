# scripts for syncing apache changes
class apachesync {

    file { '/srv/httpdconf':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/usr/local/bin/sync-apache':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/apachesync/sync-apache',
    }

    file { '/usr/local/bin/apache-graceful-all':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
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

    # rsyncd setup for httpd configs
    rsync::server::module { 'httpdconf':
        path        => '/srv/httpdconf/apache-config',
        read_only   => 'yes',
        hosts_allow => $::network::constants::mw_appserver_networks;
    }

}
