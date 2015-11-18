class mattermost::server(
    $sitename,
    $mysql_host,
    $mysql_user,
    $mysql_password,
    $mysql_db,
    $file_storage_path,
    $allow_team_creation = false,
    $allow_user_creation = true,
) {
    git::clone { 'operations/software/mattermost':
        ensure    => present,
        directory => '/srv/mattermost',
        owner     => 'www-data',
        group     => 'www-data',
        mode      => '0555',
    }

    file { '/srv/mattermost/config/config.json':
        ensure  => present,
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0444',
        content => template('mattermost/config.json.erb'),
        require => Git::Clone['operations/software/mattermost'],
        notify  => Base::Service_unit['mattermost'],
    }

    base::service_unit { 'mattermost':
        systemd => true,
    }
}
