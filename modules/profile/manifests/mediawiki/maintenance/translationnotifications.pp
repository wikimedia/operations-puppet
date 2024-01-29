class profile::mediawiki::maintenance::translationnotifications {
    # Should there be systemd timer entry for each wiki,
    # or just one which runs the scripts which iterates over
    # selected set of wikis?

    # MetaWiki
    profile::mediawiki::periodic_job { 'translationnotifications-metawiki':
        command  => '/usr/local/bin/mwscript extensions/TranslationNotifications/scripts/DigestEmailer.php --wiki metawiki',
        interval => 'Mon 10:00',
    }

    profile::mediawiki::periodic_job { 'translationnotifications-unsubscribeinactiveusers-metawiki':
        command  => '/usr/local/bin/mwscript extensions/TranslationNotifications/maintenance/UnsubscribeInactiveUsers.php --wiki metawiki --days 365 --really',
        interval => '*-01,04,07,10-02 02:00:00',
    }

    # MediaWiki
    profile::mediawiki::periodic_job { 'translationnotifications-mediawikiwiki':
        command  => '/usr/local/bin/mwscript extensions/TranslationNotifications/scripts/DigestEmailer.php --wiki mediawikiwiki',
        interval => 'Mon 10:05',
    }

    profile::mediawiki::periodic_job { 'translationnotifications-unsubscribeinactiveusers-mediawikiwiki':
        command  => '/usr/local/bin/mwscript extensions/TranslationNotifications/maintenance/UnsubscribeInactiveUsers.php --wiki mediawikiwiki --days 365 --really',
        interval => '*-01,04,07,10-02 03:30:00',
    }

    # Incubator
    profile::mediawiki::periodic_job { 'translationnotifications-unsubscribeinactiveusers-incubator':
        command  => '/usr/local/bin/mwscript extensions/TranslationNotifications/maintenance/UnsubscribeInactiveUsers.php --wiki incubatorwiki --days 365 --really',
        interval => '*-01,04,07,10-02 04:15:00',
    }

    # Wikimania
    profile::mediawiki::periodic_job { 'translationnotifications-unsubscribeinactiveusers-wikimania':
        command  => '/usr/local/bin/mwscript extensions/TranslationNotifications/maintenance/UnsubscribeInactiveUsers.php --wiki wikimaniawiki --days 365 --really',
        interval => '*-01,04,07,10-02 05:00:00',
    }

    # Commons
    profile::mediawiki::periodic_job { 'translationnotifications-unsubscribeinactiveusers-commons':
        command  => '/usr/local/bin/mwscript extensions/TranslationNotifications/maintenance/UnsubscribeInactiveUsers.php --wiki commonswiki --days 365 --really',
        interval => '*-01,04,07,10-02 05:30:00',
    }
}
