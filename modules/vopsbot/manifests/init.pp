# SPDX-License-Identifier: Apache-2.0
# @summary install and run vopsbot
class vopsbot(
    Hash[String, Vopsbot::User] $users,
    String $irc_server,
    Wmflib::Port $server_port,
    String $nickname,
    Array[String] $irc_channels,
    String $password,
    String $vo_api_id,
    String $vo_api_key,
    String $database_name = 'ircbot',
    Boolean $run_service = false,
) {
    # Install the software
    package { 'vopsbot':
        ensure => present,
    }

    # Create user
    systemd::sysuser { 'vopsbot':
        ensure      => present,
        home_dir    => '/srv/vopsbot',
        managehome  => true,
        description => 'vopsbot runner',
    }

    # configuration
    file { '/etc/vopsbot':
        ensure => directory,
        owner  => 'vopsbot',
    }
    $ircbot_config = '/etc/vopsbot/ircbot-config.json'
    $user_config = '/etc/vopsbot/users.yaml'
    $db_path = "/srv/opsbot/${database_name}.db"
    $config = {
        'server' => $irc_server,
        'port' => $server_port,
        'use_tls' => true,
        'use_sasl' => true,
        'nick' => $nickname,
        'password' => $password,
        'channels' => $irc_channels,
        'db_dsn'   => "sqlite3://file:${db_path}",
    }

    file { $ircbot_config:
        owner   => 'vopsbot',
        group   => 'vopsbot',
        mode    => '0440',
        content => to_json($config),
    }

    file { $user_config:
        owner   => 'vopsbot',
        group   => 'vopsbot',
        mode    => '0440',
        content => to_yaml($users),
    }

    # pre-generate the database
    # TODO: sync from active => passive instance.
    # TODO2: maybe use mysql
    $schema_file = '/srv/vopsbot/schema.sql'
    file { $schema_file:
        ensure => present,
        owner  => 'vopsbot',
        group  => 'vopsbot',
        mode   => '0440',
        source => 'puppet:///modules/vopsbot/schema.sql',
    }

    sqlite::db { 'vopsbot':
        ensure     => 'present',
        owner      => 'vopsbot',
        group      => 'vopsbot',
        db_path    => $db_path,
        sql_schema => $schema_file,
    }

    systemd::service { 'vopsbot':
        ensure               => $run_service.bool2str('running', 'stopped'),
        override             => false,
        monitoring_enabled   => true,
        monitoring_notes_url => 'https://wikitech.wikimedia.org/wiki/Vopsbot',
        content              => template('modules/vopsbot/systemd.unit.erb'),
    }
}
