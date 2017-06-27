class mediawiki::maintenance::parsercachepurging( $ensure = present ) {

    system::role { 'mediawiki::maintenance::parsercachepurging': description => 'Mediawiki Maintenance Server: parser cache purging' }

    cron { 'parser_cache_purging':
        ensure  => $ensure,
        user    => $::mediawiki::users::web,
        minute  => 0,
        hour    => 1,
        # Every day, Purge entries older than 22d * 86400s/d = 1900800s
        command => '/usr/local/bin/mwscript purgeParserCache.php --wiki=aawiki --age=1900800 --msleep 500 >/dev/null 2>&1',
    }
}

