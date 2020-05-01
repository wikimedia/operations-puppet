class profile::mediawiki::maintenance::initsitestats {
    profile::mediawiki::periodic_job { 'initsitestats':
        command  => '/usr/local/bin/foreachwiki initSiteStats.php --update',
        interval => '*-1,15 05:39',
    }
}
