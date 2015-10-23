# == Class: mediawiki::maintenance::jobqueue_stats
#
# Provisions a cron job which runs every minute and which reports the
# total size of the job queue to StatsD.
#
class mediawiki::maintenance::jobqueue_stats( $ensure = present ) {
    include ::mediawiki::users

    cron { 'jobqueue_stats_reporter':
        ensure  => $ensure,
        command => '/usr/local/bin/mwscript extensions/WikimediaMaintenance/getJobQueueLengths.php --report 2>/dev/null >/dev/null',
        user    => $::mediawiki::users::web,
        minute  => '*',
    }
}
