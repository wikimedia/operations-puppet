# SPDX-License-Identifier: Apache-2.0
class profile::corto(
    Stdlib::Fqdn  $active_host    = lookup('profile::corto::active_host'),
    String        $gdrive_id      = lookup('profile::corto::google_drive_id'),
    Array[String] $irc_admins     = lookup('profile::corto::irc_config::admins'),
    Array[String] $irc_chans      = lookup('profile::corto::irc_config::channels'),
    String        $irc_db_dsn     = lookup('profile::corto::irc_config::db_dsn'),
    Integer       $irc_port       = lookup('profile::corto::irc_config::port'),
    String        $irc_srv        = lookup('profile::corto::irc_config::server'),
    String        $log_level      = lookup('profile::corto::log_level'),
    String        $phab_phid      = lookup('profile::corto::phabricator_phid'),
    String        $phab_proj_phid = lookup('profile::corto::phabricator_proj_phid'),
    String        $phab_token     = lookup('profile::corto::phabricator_token'),
    String        $phab_url       = lookup('profile::corto::phabricator_url'),
) {
    if ($::fqdn == $active_host) {
        $ensure = 'present'
    } else {
        $ensure = 'absent'
    }

    class { 'corto':
        ensure         => $ensure,
        gdrive_id      => $gdrive_id,
        irc_admins     => $irc_admins,
        irc_chans      => $irc_chans,
        irc_db_dsn     => $irc_db_dsn,
        irc_port       => $irc_port,
        irc_srv        => $irc_srv,
        phab_phid      => $phab_phid,
        phab_proj_phid => $phab_proj_phid,
        phab_token     => $phab_token,
        phab_url       => $phab_url,
    }
}
