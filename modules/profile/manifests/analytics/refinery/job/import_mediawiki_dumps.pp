# == Class profile::analytics::refinery::job::import_mediawiki_dumps
# Schedules an import of page-history xmldumps and site-info jsondumps to hadoop.
#
# NOTE: This class assumes the xmldatadumps folder under which public dumps
# can be found is mounted under /mnt/data
#
class profile::analytics::refinery::job::import_mediawiki_dumps (
    $use_kerberos = lookup('profile::analytics::refinery::job::import_mediawiki_dumps::use_kerberos', { 'default_value' => false }),
) {

    # Import siteinfo-namespaces
    profile::analytics::refinery::job::import_mediawiki_dumps_config { 'refinery-import-siteinfo-dumps':
        dump_type         => 'siteinfo-namespaces',
        log_file_name     => 'import_siteinfo_dumps.log',
        timer_description => 'Schedules daily an incremental import of the current month of siteinfo-namespaces jsondumps into HDFS',
        timer_interval    => '*-*-* 02:00:00',
        use_kerberos      => $use_kerberos,
    }

    # Import pages-meta-history
    profile::analytics::refinery::job::import_mediawiki_dumps_config { 'refinery-import-page-history-dumps':
        dump_type         => 'pages-meta-history',
        log_file_name     => 'import_pages_history_dumps.log',
        timer_description => 'Schedules daily an incremental import of the current month of pages-meta-history xmldumps into HDFS',
        timer_interval    => '*-*-* 03:00:00',
        use_kerberos      => $use_kerberos,
    }

    # Import pages-meta-current
    profile::analytics::refinery::job::import_mediawiki_dumps_config { 'refinery-import-page-current-dumps':
        dump_type         => 'pages-meta-current',
        log_file_name     => 'import_pages_current_dumps.log',
        timer_description => 'Schedules daily an incremental import of the current month of pages-meta-current xmldumps into HDFS',
        timer_interval    => '*-*-* 05:00:00',
        use_kerberos      => $use_kerberos,
    }

}
