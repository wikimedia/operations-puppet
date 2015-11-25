class role::mattermost {
    class { '::mattermost::server':
        sitename          => 'Wikimedia Mattermost (Testing)',
        mysql_host        => '127.0.0.1',
        mysql_user        => 'root',
        mysql_password    => '',
        mysql_db          => 'mattermost',
        file_storage_path => '/srv/data',
    }

    class { '::mysql::server':
        package_name => 'mariadb-server-10.0',
    }

    class { '::mattermost::matterircd':
        default_team   => 'Wikimedia',
        default_server => 'mattermost.wmflabs.org',
    }
}
