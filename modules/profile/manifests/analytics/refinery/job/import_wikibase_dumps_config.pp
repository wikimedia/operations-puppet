# == Define profile::analytics::refinery::job::import_wikibase_dumps_config
#
# Renders a bash script allowing to import wikibase-dumps onto hdfs, and
# defines a kerberized monthly systemd timer launching the job.
#
# [*include_pattern*]
#   The hdfs-rsync include pattern to use to import only a subset of files.
#   '/*/*.json.bz2' for instance for all-json dumps
#
# [*local_source*]
#   The local source to hdfs-rsync. Should be a folder with trailing / containing
#   containing dates in YYYYMMDD format
#
# [*hdfs_destination*]
#   The hdfs destination of the hdfs-rsync. Should be a folder
#
# [*timer_description*]
#   The description of the timer.
#
# [*timer_interval*]
#   The interval to be used for the timer.
#   Format: DayOfWeek Year-Month-Day Hour:Minute:Second
#
# [*script_path*]
#   The path to be used for the import-script.
#   Default: /usr/local/bin/${title}
#

define profile::analytics::refinery::job::import_wikibase_dumps_config(
    $include_pattern,
    $local_source,
    $hdfs_destination,
    $timer_description,
    $timer_interval,
    $script_path = "/usr/local/bin/${title}",
    $ensure = 'present',
) {

    file { $script_path:
        ensure  => $ensure,
        content => template('profile/analytics/refinery/job/refinery-import-wikibase-dumps.sh.erb'),
        mode    => '0550',
        owner   => 'analytics',
        group   => 'analytics',
    }

    kerberos::systemd_timer { $title:
        ensure      => $ensure,
        description => $timer_description,
        command     => $script_path,
        interval    => $timer_interval,
        user        => 'analytics',
        require     => File[$script_path],
    }

}
