class mediawiki::maintenance::parsercachepurging( $ensure = present ) {

    system::role { 'mediawiki::maintenance::parsercachepurging': description => 'Mediawiki Maintenance Server: parser cache purging' }

    cron { 'parser_cache_purging':
        ensure  => $ensure,
        user    => $::mediawiki::users::web,
        minute  => 0,
        hour    => 1,
        weekday => '*',
        # Every day, Purge entries older than 24d * 86400s/d = 2073600s
        command => '/usr/local/bin/mwscript purgeParserCache.php --wiki=aawiki --age=2073600 --msleep 500 >/dev/null 2>&1',
    }
}

