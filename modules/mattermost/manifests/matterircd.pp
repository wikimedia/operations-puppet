class mattermost::matterircd {
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
