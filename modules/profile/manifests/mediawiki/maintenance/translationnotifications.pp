class profile::mediawiki::maintenance::translationnotifications {
    # Should there be systemd timer entry for each wiki,
    # or just one which runs the scripts which iterates over
    # selected set of wikis?

    profile::mediawiki::periodic_job { 'translationnotifications-metawiki':
        command  => '/usr/local/bin/mwscript extensions/TranslationNotifications/scripts/DigestEmailer.php --wiki metawiki',
        interval => 'Mon 10:00',
    }

    profile::mediawiki::periodic_job { 'translationnotifications-mediawikiwiki':
        command  => '/usr/local/bin/mwscript extensions/TranslationNotifications/scripts/DigestEmailer.php --wiki mediawikiwiki',
        interval => 'Mon 10:05',
    }
}
