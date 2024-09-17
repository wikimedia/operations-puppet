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
# [*$irc_admins*]
#   IRC nicks allowed to control Corto.
#
#   Default: undef
#
# [*$irc_chans*]
#   IRC channels that Corto will join.
#
#   Default: undef
#
# [*$irc_db_dsn*]
#   Data source name connection path for the IRC bot
#   Example: sqlite3:///var/lib/corto/ircbot.db
#
#   Default: undef
#
# [*$irc_nick*]
#   IRC nick to use in channels.
#
#   Default: 'cortobot'
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
# [*$log_level*]
#   Log level to set Corto's output.
#
#   Default: info
#
# [*$phab_phid*]
#   Phabricator user PHID
#   Example: PHID-USER-12345678912345678912
#
#   Default: undef
#
# [*$phab_proj_phid*]
#   Phabricator incident project PHID
#   Example: PHID-PROJ-12345678912345678912
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

class corto(
    Wmflib::Ensure   $ensure,
    String           $gdrive_id,
    Array[String]    $irc_admins,
    Array[String]    $irc_chans,
    String           $irc_db_dsn,
    Integer          $irc_port,
    String           $irc_srv,
    String           $phab_phid,
    String           $phab_proj_phid,
    String           $phab_token,
    String           $phab_url,
    Stdlib::Unixpath $gdrive_creds_path = '/etc/corto/gdrive-creds.json',
    String           $irc_nick = 'cortobot',
    Boolean          $irc_use_tls = true,
    String           $log_level = 'info',
) {
    package { 'corto':
        ensure => $ensure,
    }

    $config = {
        google_drive_creds_path => $gdrive_creds_path,
        google_drive_id         => $gdrive_id,
        phabricator_proj_phid   => $phab_proj_phid,
        phabricator_url         => $phab_url,
        phabricator_token       => $phab_token,
        phabricator_phid        => $phab_phid,
        log_level               => $log_level,
        irc_config              => {
            server   => $irc_srv,
            port     => $irc_port,
            use_tls  => $irc_use_tls,
            nick     => $irc_nick,
            channels => $irc_chans,
            db_dsn   => $irc_db_dsn,
            admins   => $irc_admins,
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

    $service_run = $ensure ? {
        present => running,
        absent => stopped,
    }

    $service_enable = $ensure ? {
        present => true,
        absent => false,
    }

    service { 'corto':
        ensure => $service_run,
        enable => $service_enable,
    }

}
