# SPDX-License-Identifier: Apache-2.0
# == Class profile::analytics::refinery::job::import_mediawiki_dumps
# Schedules an import of page-history xmldumps and site-info jsondumps to hadoop.
#
# NOTE: This class assumes the xmldatadumps folder under which public dumps
# can be found is mounted under /mnt/data
#
class profile::analytics::refinery::job::import_mediawiki_dumps (
    Wmflib::Ensure $ensure_timers = lookup('profile::analytics::refinery::job::import_mediawiki_dumps::ensure_timers', { 'default_value' => 'present' }),
) {

    # Import siteinfo-namespaces
    profile::analytics::refinery::job::import_mediawiki_dumps_config { 'refinery-import-siteinfo-dumps':
        ensure            => $ensure_timers,
        dump_type         => 'siteinfo-namespaces',
        log_file_name     => 'import_siteinfo_dumps.log',
        timer_description => 'Schedules daily an incremental import of the current month of siteinfo-namespaces jsondumps into HDFS',
        timer_interval    => '*-*-* 02:00:00',
    }

    # Import pages-meta-history
    profile::analytics::refinery::job::import_mediawiki_dumps_config { 'refinery-import-page-history-dumps':
        ensure            => $ensure_timers,
        dump_type         => 'pages-meta-history',
        log_file_name     => 'import_pages_history_dumps.log',
        timer_description => 'Schedules daily an incremental import of the current month of pages-meta-history xmldumps into HDFS',
        timer_interval    => '*-*-* 03:00:00',
    }

    # Import pages-meta-current
    profile::analytics::refinery::job::import_mediawiki_dumps_config { 'refinery-import-page-current-dumps':
        ensure            => $ensure_timers,
        dump_type         => 'pages-meta-current',
        log_file_name     => 'import_pages_current_dumps.log',
        timer_description => 'Schedules daily an incremental import of the current month of pages-meta-current xmldumps into HDFS',
        timer_interval    => '*-*-* 05:00:00',
    }

}
