# == Class profile::analytics::refinery::job::import_wikitext_dumps
# Schedules an import of page-history xmldumps to hadoop.
#
# NOTE: This class assumes the xmldatadumps folder under which public dumps
# can be found is mounted under /mnt/data
#
class profile::analytics::refinery::job::import_wikitext_dumps (
    $use_kerberos = lookup('profile::analytics::refinery::job::import_wikitext_dumps::use_kerberos', { 'default_value' => false }),
) {
    require ::profile::analytics::refinery

    $refinery_path          = $profile::analytics::refinery::path

    $wiki_file              = '/mnt/hdfs/wmf/refinery/current/static_data/mediawiki/grouped_wikis/labs_grouped_wikis.csv'
    $input_directory_base   = '/mnt/data/xmldatadumps/public'
    $output_directory_base  = '/wmf/data/raw/mediawiki/xmldumps'
    $log_file               = "${::profile::analytics::refinery::log_dir}/import_wikitext_dumps.log"

    file { '/usr/local/bin/refinery-import-page-history-dumps':
        content => template('profile/analytics/refinery/job/refinery-import-wikitext-dumps.sh.erb'),
        mode    => '0550',
        owner   => 'analytics',
        group   => 'analytics',
    }

    kerberos::systemd_timer { 'refinery-import-page-history-dumps':
        description  => 'Schedules daily an incremental import of the current month of page-history xmldumps into Hadoop',
        command      => '/usr/local/bin/refinery-import-page-history-dumps',
        interval     => '*-*-* 03:00:00',
        user         => 'analytics',
        use_kerberos => $use_kerberos,
        require      => File['/usr/local/bin/refinery-import-page-history-dumps'],
    }
}

