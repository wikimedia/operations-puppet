# SPDX-License-Identifier: Apache-2.0
class profile::vopsbot(
    Hash[String, Vopsbot::User] $vo_users = lookup('profile::vopsbot::vo_users'),
    String $active_host = lookup('profile::icinga::active_host'),
    String $nickname    = lookup('profile::vopsbot::nickname'),
    String $password    = lookup('profile::vopsbot::password'),
    String $vo_api_id   = lookup('profile::vopsbot::vo_api_id'),
    String $vo_api_key  = lookup('profile::vopsbot::vo_api_key'),
    Array[String] $channels = lookup('profile::vopsbot::irc_channels')
) {
    # Create user
    systemd::sysuser { 'vopsbot':
        ensure      => present,
        home_dir    => '/srv/vopsbot',
        managehome  => true,
        description => 'vopsbot runner',
        before      => Class['Vopsbot'],
    }

    class { 'vopsbot':
        users         => $vo_users,
        irc_server    => 'irc.libera.chat',
        server_port   => 6697,
        nickname      => $nickname,
        password      => $password,
        irc_channels  => $channels,
        vo_api_id     => $vo_api_id,
        vo_api_key    => $vo_api_key,
        database_name => 'vopsbot',
        run_service   => ($active_host == $::fqdn),
    }
}
