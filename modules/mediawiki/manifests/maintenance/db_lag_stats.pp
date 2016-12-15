# == Class: mediawiki::maintenance::db_lag_stats
#
# Provisions a cron job which runs every minute and which reports the
# the amount of lag for MediaWiki-pooled DBs to StatsD.
#
class mediawiki::maintenance::db_lag_stats( $ensure = present ) {
    include ::mediawiki::users

    cron { 'db_lag_stats_reporter':
        ensure  => $ensure,
        command => '/usr/local/bin/mwscript maintenance/getLagTimes.php --wiki aawiki --report 2>/dev/null >/dev/null',
        user    => $::mediawiki::users::web,
        minute  => '*',
    }
}
