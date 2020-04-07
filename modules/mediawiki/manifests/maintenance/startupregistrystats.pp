class mediawiki::maintenance::startupregistrystats(
    $ensure = present
) {
    # group0: test.wikipedia.org
    cron { 'startupregistrystats-testwiki':
        ensure  => $ensure,
        user    => $::mediawiki::users::web,
        minute  => 10,
        command => '/usr/local/bin/mwscript extensions/WikimediaMaintenance/blameStartupRegistry.php --wiki testwiki --record-stats > /dev/null 2>&1',
    }

    # group0: mediawiki.org
    cron { 'startupregistrystats-mediawikiwiki':
        ensure  => $ensure,
        user    => $::mediawiki::users::web,
        minute  => 15,
        command => '/usr/local/bin/mwscript extensions/WikimediaMaintenance/blameStartupRegistry.php --wiki mediawikiwiki --record-stats > /dev/null 2>&1',
    }

    # large wikis (inludes several group1 and group2 wikis)
    cron { 'startupregistrystats':
        ensure  => $ensure,
        user    => $::mediawiki::users::web,
        minute  => 35,
        command => '/usr/local/bin/foreachwikiindblist large extensions/WikimediaMaintenance/blameStartupRegistry.php --record-stats > /dev/null 2>&1',
    }
}
