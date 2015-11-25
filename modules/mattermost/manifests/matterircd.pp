class mattermost::matterircd(
    $default_team,
    $default_server,
) {
    git::clone { 'operations/software/matterircd':
        ensure    => present,
        branch    => 'deploy',
        directory => '/srv/matterircd',
        owner     => 'www-data',
        group     => 'www-data',
        mode      => '0775',
    }

    base::service_unit { 'matterircd':
        systemd => true,
    }
}
