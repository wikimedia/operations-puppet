# SPDX-License-Identifier: Apache-2.0
# @summary profile to install vopsbot
# @param active_host fqdn of the active host
# @param nickname irc nick to use
# @param password irc password to use
# @param vo_api_id VictorOps ID
# @param vo_api_key VictorOps API key
# @param channels list of channels to join
# @param vo_users list of authorised users
class profile::vopsbot(
    String                      $active_host = lookup('profile::icinga::active_host'),
    String                      $nickname    = lookup('profile::vopsbot::nickname'),
    String                      $password    = lookup('profile::vopsbot::password'),
    String                      $vo_api_id   = lookup('profile::vopsbot::vo_api_id'),
    String                      $vo_api_key  = lookup('profile::vopsbot::vo_api_key'),
    Array[String]               $channels    = lookup('profile::vopsbot::irc_channels'),
    Hash[String, Vopsbot::User] $vo_users    = lookup('profile::vopsbot::vo_users'),
) {

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
        run_service   => ($active_host == $facts['networking']['fqdn']),
    }
}
