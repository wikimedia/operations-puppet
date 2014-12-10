########################################################################
#
# Maintenance scripts should always run as apache and never as mwdeploy.
#
# This is 1) for security reasons and 2) for consistent file ownership
# (if MediaWiki creates (temporary) files, they must be owned by apache)
#
########################################################################

class mediawiki::maintenance::parsercachepurging( $ensure = present ) {

    system::role { 'mediawiki::maintenance::parsercachepurging': description => 'Misc - Maintenance Server: parser cache purging' }

    cron { 'parser_cache_purging':
        ensure  => $ensure,
        user    => 'apache',
        minute  => 0,
        hour    => 1,
        weekday => 0,
        # Purge entries older than 30d * 86400s/d = 2592000s
        command => '/usr/local/bin/mwscript purgeParserCache.php --wiki=aawiki --age=2592000 >/dev/null 2>&1',
    }
}

