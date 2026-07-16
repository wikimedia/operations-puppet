# SPDX-License-Identifier: Apache-2.0
class profile::corto(
    Stdlib::Fqdn  $active_host      = lookup('profile::corto::active_host'),
    String        $gdrive_id        = lookup('profile::corto::google_drive_id'),
    String        $gdoc_handover_id = lookup('profile::corto::google_handover_doc_id'),
    Array[String] $irc_chans        = lookup('profile::corto::irc_config::channels'),
    Integer       $irc_port         = lookup('profile::corto::irc_config::port'),
    String        $irc_srv          = lookup('profile::corto::irc_config::server'),
    String        $irc_nick         = lookup('profile::corto::irc_config::nick'),
    String        $irc_pass         = lookup('profile::corto::irc_config::password'),
    String        $phab_user        = lookup('profile::corto::phabricator_user'),
    String        $phab_project     = lookup('profile::corto::phabricator_project'),
    String        $phab_token       = lookup('profile::corto::phabricator_token'),
    String        $phab_url         = lookup('profile::corto::phabricator_url'),
    String        $phab_view_policy = lookup('profile::corto::phabricator_policy::view'),
    String        $phab_edit_policy = lookup('profile::corto::phabricator_policy::edit'),
) {
    if ($facts['networking']['fqdn'] == $active_host) {
        $ensure = 'present'
    } else {
        $ensure = 'absent'
    }

    class { 'corto':
        ensure           => $ensure,
        gdrive_id        => $gdrive_id,
        gdoc_handover_id => $gdoc_handover_id,
        irc_chans        => $irc_chans,
        irc_port         => $irc_port,
        irc_srv          => $irc_srv,
        irc_nick         => $irc_nick,
        irc_pass         => $irc_pass,
        phab_user        => $phab_user,
        phab_project     => $phab_project,
        phab_token       => $phab_token,
        phab_url         => $phab_url,
        phab_view_policy => $phab_view_policy,
        phab_edit_policy => $phab_edit_policy,
    }
}
