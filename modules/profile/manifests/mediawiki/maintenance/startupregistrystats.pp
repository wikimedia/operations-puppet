class profile::mediawiki::maintenance::startupregistrystats {
    # group0: test.wikipedia.org
    profile::mediawiki::periodic_job { 'startupregistrystats-testwiki':
        command  => '/usr/local/bin/mwscript extensions/WikimediaMaintenance/blameStartupRegistry.php --wiki testwiki --record-stats',
        interval => '*:10'
    }

    # group0: mediawiki.org
    profile::mediawiki::periodic_job { 'startupregistrystats-mediawikiwiki':
        command  => '/usr/local/bin/mwscript extensions/WikimediaMaintenance/blameStartupRegistry.php --wiki mediawikiwiki --record-stats',
        interval => '*:15'
    }

    # large wikis (inludes several group1 and group2 wikis)
    profile::mediawiki::periodic_job { 'startupregistrystats':
        command  => '/usr/local/bin/foreachwikiindblist large extensions/WikimediaMaintenance/blameStartupRegistry.php --record-stats',
        interval => '*:35'
    }
}
