# SPDX-License-Identifier: Apache-2.0
## profile::dbbackups::check
## Description:
# Check backups are being generated regularly and correctly,
# they are "fresh" (last backup isn't too old) and seemingly
# correct. Generate an icinga alert if not.
# Only metadata checks are done- full backup tests are to be
# done on a separate class.
## Usage:
# include '::profile::dbbackups::check'
## Parameters:
# * $enabled: if true, it installs the config, the software and the checks
#             exports for icinga. if false, it setups the config and the
#             software, but doesn't set up the individual nrpe checks and
#             exports, so it is in "standby", ready to be enabled if needed.
# * $backups: Hash with the configuration of backup monitoring, with the current
#             structure:
#             <section1>:
#               <type1>:
#               - <dc1>
#               - <dc2>
#               - ...
#               <type2>:
#               - <dc1>
#               - <dc2>
#               - ...
#             <section2>
#               ...
# * $freshness: For each backup time in $backups (as a key), it lists the max
#               time (in seconds) a backups will be stale, after which the
#               alarme will go off.
# * $min_size: minimum size that all backups should be equal or higher, or it
#              will alert.
# * $warn_size_percentage: Percentage (a float from 0 to 100), after which, if
#                          the latest backup has grown or shrink more than this
#                          in relation to the previous run, the alerm will go
#                          off with a warning
# * $crit_size_percentage: Percentage (a float from 0 to 100), after which, if
#                          the latest backup has grown or shrink more than this
#                          in relation to the previous run, the alerm will go
#                          off with a critical alert
# * $es_backups_check: if true, it setups a weekly check involving making sure
#                      that all es configured and active backups take less than
#                      a configurable amount of hours to run; otherwise,
#                      it sends an alert by email,
# * $es_max_hours: Maximum amount of hours an ES (content db) backup should
#                  take to backup, beyond which an email is sent,
# * $es_alert_email: Email address where to sent the alerts of ES backups taking
#                    too much time.
# * $db_host: IP, full qualified domain or hostname where the backups statistics
#             are hosted
# * $db_user: Username with read grants for the mysql database where the backup
#             statistics are stored
# * $db_password: Database password for the previous user
# * $db_database: Schema where the backup statistics and metrics are stored.
class profile::dbbackups::check (
    $enabled              = lookup('profile::dbbackups::check::enabled', Boolean, ),
    $backups              = lookup('profile::dbbackups::check::backups', Hash, ),
    $freshness            = lookup('profile::dbbackups::check::freshness', Hash[String, Integer], ),
    $min_size             = lookup('profile::dbbackups::check::min_size', Integer[0, infinity], ),
    $warn_size_percentage = lookup('profile::dbbackups::check::warn_size_percentage', Float[0.0, 100.0]),
    $crit_size_percentage = lookup('profile::dbbackups::check::crit_size_percentage', Float[0.0, 100.0]),
    $es_backups_check     = lookup('profile::dbbackups::check::es_backups_check', Boolean, ),
    $es_max_hours         = lookup('profile::dbbackups::check::es_max_hours', Float[0.0, 8760.0], ),
    $es_alert_email       = lookup('profile::dbbackups::check::es_alert_email', String, ),
    $db_host              = lookup('profile::dbbackups::check::db_host', String, ),
    $db_user              = lookup('profile::dbbackups::check::db_user', String, ),
    $db_password          = lookup('profile::dbbackups::check::db_password', String, ),
    $db_database          = lookup('profile::dbbackups::check::db_database', String, ),
) {
    require ::profile::mariadb::wmfmariadbpy
    class { 'dbbackups::check_common':
        valid_sections_file => 'puppet:///modules/profile/dbbackups/valid_sections.txt',
    }

    # only install the software on disabled ("passive") hosts, not the actual
    # icinga checks
    if $enabled {
        $backups.each |String $section, Hash $section_hash| {
            $section_hash.each |String $type, Array[String] $type_array| {
                $type_array.each |String $dc| {
                    dbbackups::check { "${dc}-${section}-${type}":
                        section              => $section,
                        datacenter           => $dc,
                        type                 => $type,
                        freshness            => $freshness[$type],
                        min_size             => $min_size,
                        warn_size_percentage => $warn_size_percentage,
                        crit_size_percentage => $crit_size_percentage,
                        db_user              => $db_user,
                        db_host              => $db_host,
                        db_password          => $db_password,
                        db_database          => $db_database,
                    }
                }
            }
        }
    }

    # Check all external storage backups for backup time, if enabled
    dbbackups::check_es { 'check-es-backups-duration':
        enabled     => $es_backups_check,
        max_hours   => $es_max_hours,
        email       => $es_alert_email,
        db_user     => $db_user,
        db_host     => $db_host,
        db_password => $db_password,
        db_database => $db_database,
    }
}

