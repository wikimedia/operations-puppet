# == Define profile::analytics::refinery::job::import_mediawiki_dumps_config
#
# Renders a bash script allowing to import mediawiki-dumps onto hdfs, and
# defines a kerberized monthly systemd timer launching the job.
#
# [*dump_type*]
#   The dump-type to import (pages-meta-history, siteinfo-namespaces etc).
#
# [*log_file_name*]
#   The file used by the importer for logging into the refinery-log folder
#   defined in the refinery profile.
#
# [*timer_description*]
#   The description to be used for the timer.
#
# [*timer_interval*]
#   The interval to be used for the timer.
#   Format: DayOfWeek Year-Month-Day Hour:Minute:Second
#
# [*use_kerberos*]
#   Whether the timer should use the kerberos-wrapper.
#
# [*wiki_file*]
#   The file containing the wikis to import.
#   Format: csv with wiki database name as first column.
#   Default: /mnt/hdfs/wmf/refinery/current/static_data/mediawiki/grouped_wikis/labs_grouped_wikis.csv
#
# [*input_directory_base*]
#   The path of the xmldatadumps/public mount from which to import files.
#   Default: /mnt/data/xmldatadumps/public
#
# [*output_directory_base*]
#   The base-path where to store imported files in sub-folders.
#   Sub-folders: dump_type/date/wikidb.
#   Default: wmf/data/raw/mediawiki/dumps
#
# [*script_path*]
#   The path to be used for the import-script.
#   Default: /usr/local/bin/${title}
#

define profile::analytics::refinery::job::import_mediawiki_dumps_config(
    $dump_type,
    $log_file_name,
    $timer_description,
    $timer_interval,
    $use_kerberos,
    $wiki_file = '/mnt/hdfs/wmf/refinery/current/static_data/mediawiki/grouped_wikis/labs_grouped_wikis.csv',
    $input_directory_base = '/mnt/data/xmldatadumps/public',
    $output_directory_base = '/wmf/data/raw/mediawiki/dumps',
    $script_path = "/usr/local/bin/${title}",
    $ensure = 'present',
) {

    require ::profile::analytics::refinery

    $refinery_path = $profile::analytics::refinery::path
    $log_file      = "${profile::analytics::refinery::log_dir}/${log_file_name}"

    file { $script_path:
        ensure  => $ensure,
        content => template('profile/analytics/refinery/job/refinery-import-mediawiki-dumps.sh.erb'),
        mode    => '0550',
        owner   => 'analytics',
        group   => 'analytics',
    }

    kerberos::systemd_timer { $title:
        ensure       => $ensure,
        description  => $timer_description,
        command      => $script_path,
        interval     => $timer_interval,
        user         => 'analytics',
        use_kerberos => $use_kerberos,
        require      => File[$script_path],
    }

}
