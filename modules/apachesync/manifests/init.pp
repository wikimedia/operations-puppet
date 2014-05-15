# scripts for syncing apache changes
class apachesync {


    file { '/etc/cluster':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => $::site,
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
		path        => '/srv/httpdconf',
		read_only   => 'true',
		hosts_allow => $::network::constants::mw_appserver_networks;
	}
}
