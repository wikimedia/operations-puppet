class profile::mediawiki::maintenance::initsitestats {
    profile::mediawiki::periodic_job { 'initsitestats':
        command  => '/usr/local/bin/foreachwiki initSiteStats.php --update',
        interval => '*-*-* 05:39:00',
    }
}
