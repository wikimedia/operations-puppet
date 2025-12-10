# SPDX-License-Identifier: Apache-2.0
# == Class: corto
# Deployment of Corto configuration, services, and executable
#
# === Parameters
# [*ensure*]
#   If 'present', the module will be configured with all users,
#   files, and services enabled. If 'absent', all of these are
#   removed/disabled.
#
#   Default: 'present'
#
# [*gdrive_creds_path*]
#   Google Drive ID storing the incident documentation.
#
#   Default: /etc/corto/gdrive-creds.json
#
# [*gdrive_id*]
#   Google Drive ID storing the incident documentation.
#
#   Default: undef
#
# [*gdoc_handover_id*]
#   Google doc ID used to record handover notes
#
#   Default: undef
#
# [*$irc_chans*]
#   IRC channels that Corto will join.
#
#   Default: undef
#
# [*$irc_nick*]
#   IRC nick to use in channels.
#
#   Default: 'cortobot'
#
# [*$irc_pass*]
#   Password to use for the IRC nick.
#
#   Default: undef
#
# [*$irc_port*]
#   IRC connection port.
#
#   Default: undef
#
# [*$irc_srv*]
#   IRC server hostname for connection.
#
#   Default: undef
#
# [*$irc_use_tls*]
#   Whether to use TLS or not.
#
#   Default: true
#
# [*$phab_user*]
#   Phabricator user name
#   Example: corto
#
#   Default: undef
#
# [*$phab_project*]
#   Phabricator incident project
#   Example: Wikimedia-Incident
#
#   Default: undef
#
# [*$phab_token*]
#   Authentication token for Phabricator access
#
#   Default: undef
#
# [*$phab_url*]
#   Endpoint to authenticate against.
#
#   Default: undef
#
# [*$phab_view_policy*]
#   Phabricator policy used for viewing.
#
#   Default: #acl_sre-team
#
# [*$phab_edit_policy*]
#   Phabricator policy used for editing.
#
#   Default: #acl_sre-team

class corto(
    Wmflib::Ensure   $ensure,
    String           $gdrive_id,
    String           $gdoc_handover_id,
    Array[String]    $irc_chans,
    Integer          $irc_port,
    String           $irc_srv,
    String           $phab_user,
    String           $phab_project,
    String           $phab_token,
    String           $phab_url,
    String           $phab_view_policy = '#acl_sre-team',
    String           $phab_edit_policy = '#acl_sre-team',
    Stdlib::Unixpath $gdrive_creds_path = '/etc/corto/gdrive-creds.json',
    String           $irc_nick = 'cortobot',
    String           $irc_pass = undef,
    Boolean          $irc_use_tls = true,
) {
    package { 'corto':
        ensure => $ensure,
    }

    $config = {
        google_drive_creds_path => $gdrive_creds_path,
        google_drive_id         => $gdrive_id,
        google_handover_doc_id  => $gdoc_handover_id,
        phabricator             => {
            project  => $phab_project,
            url      => $phab_url,
            token    => $phab_token,
            user     => $phab_user,
            policy   => {
                view => $phab_view_policy,
                edit => $phab_edit_policy,
          },
        },
        irc_config              => {
            server   => $irc_srv,
            port     => $irc_port,
            use_tls  => $irc_use_tls,
            nick     => $irc_nick,
            password => $irc_pass,
            channels => $irc_chans,
        },
    }

    $ensure_conf_dir = $ensure ? {
        absent  => $ensure,
        default => 'directory',
    }

    file { '/etc/corto/':
        ensure => $ensure_conf_dir,
        owner  => 'corto',
        group  => 'root',
        mode   => '0700',
        force  => true,
    }

    file { '/var/lib/corto/':
        ensure => $ensure_conf_dir,
        owner  => 'corto',
        group  => 'root',
        mode   => '0700',
        force  => true,
    }

    file { '/etc/corto/config.yaml':
        ensure    => $ensure,
        owner     => 'corto',
        group     => 'root',
        mode      => '0400',
        content   => to_yaml($config),
        backup    => false,
        show_diff => false,
    }

    file { $gdrive_creds_path:
        ensure    => $ensure,
        owner     => 'corto',
        group     => 'root',
        mode      => '0400',
        show_diff => false,
        backup    => false,
        content   => secret('corto/gdrive-creds.json'),
    }

    $service_enable = $ensure ? {
        present => true,
        absent => false,
    }

    service { 'corto':
        ensure => stdlib::ensure($ensure, 'service'),
        enable => $service_enable,
    }

    profile::auto_restarts::service { 'corto':
      ensure => $ensure,
    }
}
