
class mediawiki::maintenance::pagetriage( $ensure = present ) {

    require mediawiki

    system::role { 'mediawiki::maintenance::pagetriage': description => 'Misc - Maintenance Server: pagetriage extension' }

    cron { 'pagetriage_cleanup_en':
        ensure   => $ensure,
        user     => $::mediawiki::users::web,
        minute   => 55,
        hour     => 20,
        monthday => '*/2',
        command  => '/usr/local/bin/mwscript extensions/PageTriage/cron/updatePageTriageQueue.php enwiki > /var/log/mediawiki/updatePageTriageQueue.en.log',
    }

    cron { 'pagetriage_cleanup_testwiki':
        ensure   => $ensure,
        user     => $::mediawiki::users::web,
        minute   => 55,
        hour     => 14,
        monthday => '*/2',
        command  => '/usr/local/bin/mwscript extensions/PageTriage/cron/updatePageTriageQueue.php testwiki > /var/log/mediawiki/updatePageTriageQueue.test.log',
    }
}

