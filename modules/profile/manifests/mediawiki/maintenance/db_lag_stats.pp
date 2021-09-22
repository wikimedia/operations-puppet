# == Class: profile::mediawiki::maintenance::db_lag_stats
#
# Provisions a periodic job which runs every minute and which reports the
# the amount of lag for MediaWiki-pooled DBs to StatsD.
#
class profile::mediawiki::maintenance::db_lag_stats {
    profile::mediawiki::periodic_job { 'db_lag_stats_reporter':
        command  => '/usr/local/bin/mwscript maintenance/getLagTimes.php --wiki aawiki --report',
        interval => '*:*:00',
    }
}
