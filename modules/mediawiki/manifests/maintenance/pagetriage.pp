########################################################################
#
# Maintenance scripts should always run as apache and never as mwdeploy.
#
# This is 1) for security reasons and 2) for consistent file ownership
# (if MediaWiki creates (temporary) files, they must be owned by apache)
#
########################################################################

class mediawiki::maintenance::pagetriage( $ensure = present ) {

    system::role { 'mediawiki::maintenance::pagetriage': description => 'Misc - Maintenance Server: pagetriage extension' }

    cron { 'pagetriage_cleanup_en':
        ensure   => $ensure,
        user     => apache,
        minute   => 55,
        hour     => 20,
        monthday => '*/2',
        command  => '/usr/local/bin/mwscript extensions/PageTriage/cron/updatePageTriageQueue.php enwiki > /var/log/mediawiki/updatePageTriageQueue.en.log',
    }

    cron { 'pagetriage_cleanup_testwiki':
        ensure   => $ensure,
        user     => apache,
        minute   => 55,
        hour     => 14,
        monthday => '*/2',
        command  => '/usr/local/bin/mwscript extensions/PageTriage/cron/updatePageTriageQueue.php testwiki > /var/log/mediawiki/updatePageTriageQueue.test.log',
    }
}

