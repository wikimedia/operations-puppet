class profile::mediawiki::maintenance::parsercachepurging {

    system::role { 'mediawiki::maintenance::parsercachepurging': description => 'MediaWiki Maintenance Server: parser cache purging' }

    profile::mediawiki::periodic_job { 'parser_cache_purging':
        # Every day, Purge entries older than 30d * 86400s/d = 2592000s
        command  => '/usr/local/bin/mwscript purgeParserCache.php --wiki=aawiki --age=2592000 --msleep 500',
        interval => '01:00',
    }
}
