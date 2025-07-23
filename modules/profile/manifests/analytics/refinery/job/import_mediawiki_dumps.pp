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

}
