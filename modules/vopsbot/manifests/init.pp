# SPDX-License-Identifier: Apache-2.0
# @summary install and run vopsbot
# @param users list of authorised users
# @param irc_server the irc server to connect to
# @param server_port the irc server port to connect to
# @param nickname irc nick to use
# @param irc_channels list of channels to join
# @param password irc password to use
# @param vo_api_id VictorOps ID
# @param vo_api_key VictorOps API key
# @param active_alert_host fqdn of the active alert host
# @param passive_alert_hosts array of fqdn of the passive alertmanager hosts
# @param database_name name of the database to use
# @param run_service indicate if we should run the service
# @param daemon_user the user used to run the vopsbot daemon
class vopsbot(
    Hash[String, Vopsbot::User] $users,
    String $irc_server,
    Stdlib::Port $server_port,
    String $nickname,
    Array[String] $irc_channels,
    String $password,
    String $vo_api_id,
    String $vo_api_key,
    Stdlib::Host $alertmanager_active_host,
    Array[Stdlib::Host] $alertmanager_passive_hosts,
    String $database_name = 'ircbot',
    Boolean $run_service = false,
    String $daemon_user = 'vopsbot',
) {
    $data_path = '/srv/vopsbot'
    # Install the software
    package { 'vopsbot':
        ensure => present,
    }

    # TODO: add this to the debian package
    # https://gitlab.wikimedia.org/repos/sre/vopsbot/-/merge_requests/8
    systemd::sysuser { $daemon_user:
        ensure      => present,
        home_dir    => $data_path,
        description => 'vopsbot runner',
    }

    # configuration
    file { '/etc/vopsbot':
        ensure => directory,
        owner  => $daemon_user,
    }
    $ircbot_config = '/etc/vopsbot/ircbot-config.json'
    $user_config = '/etc/vopsbot/users.yaml'
    $db_path = "${data_path}/${database_name}.db"
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
        ensure  => file,
        owner   => $daemon_user,
        group   => $daemon_user,
        mode    => '0440',
        content => to_json($config),
        notify  => Systemd::Service['vopsbot'],
    }

    file { $user_config:
        ensure  => file,
        owner   => $daemon_user,
        group   => $daemon_user,
        mode    => '0440',
        content => to_yaml($users),
        notify  => Systemd::Service['vopsbot'],
    }

    file { $data_path:
        ensure => directory,
        owner  => $daemon_user,
        group  => $daemon_user,
        mode   => '0755',
    }
    # pre-generate the database
    # TODO: maybe use mysql
    $schema_file = "${data_path}/schema.sql"
    file { $schema_file:
        ensure => file,
        owner  => $daemon_user,
        group  => $daemon_user,
        mode   => '0440',
        source => 'puppet:///modules/vopsbot/schema.sql',
    }

    sqlite::db { 'vopsbot':
        ensure     => 'present',
        owner      => $daemon_user,
        group      => $daemon_user,
        db_path    => $db_path,
        sql_schema => $schema_file,
        require    => File[$schema_file],
    }

    rsync::quickdatacopy { 'vopsbot-sync-db':
        ensure              => present,
        auto_sync           => true,
        source_host         => $alertmanager_active_host,
        dest_host           => $alertmanager_passive_hosts,
        module_path         => $schema_file,
        server_uses_stunnel => true,
        chown               => "${daemon_user}:${daemon_user}",
    }

    systemd::service { 'vopsbot':
        ensure   => $run_service.bool2str('present', 'absent'),
        override => false,
        content  => template('vopsbot/systemd.unit.erb'),
        require  => Systemd::Sysuser[$daemon_user],
    }

    profile::auto_restarts::service { 'vopsbot':
        ensure => stdlib::ensure($run_service)
    }
}
