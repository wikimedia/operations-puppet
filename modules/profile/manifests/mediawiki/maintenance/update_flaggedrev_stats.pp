class profile::mediawiki::maintenance::update_flaggedrev_stats {

    profile::mediawiki::periodic_job { 'update_flaggedrev_stats':
        command  => '/usr/local/bin/mwscriptwikiset extensions/FlaggedRevs/maintenance/updateStats.php flaggedrevs.dblist',
        interval => '00:08'
    }
}
