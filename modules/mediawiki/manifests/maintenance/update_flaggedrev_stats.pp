class mediawiki::maintenance::update_flaggedrev_stats( $ensure = present ) {

    cron { 'update_flaggedrev_stats':
        ensure  => $ensure,
        command => '/usr/local/bin/mwscriptwikiset extensions/FlaggedRevs/maintenance/updateStats.php flaggedrevs.dblist > /dev/null',
        user    => $::mediawiki::users::web,
        hour    => '*/2',
        minute  => '0',
    }
}
