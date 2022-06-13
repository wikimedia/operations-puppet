# a cronjob for updatequerypages for enwiki
class profile::mediawiki::maintenance::updatequerypages::enwiki::cronjob {

    profile::mediawiki::periodic_job { 'updatequerypages_lonelypages_s1':
        command  => '/usr/local/bin/mwscriptwikiset updateSpecialPages.php s1.dblist --override --only=Lonelypages',
        interval => '*-15 01:00',
    }

    profile::mediawiki::periodic_job { 'updatequerypages_mostcategories_s1':
        command  => '/usr/local/bin/mwscriptwikiset updateSpecialPages.php s1.dblist --override --only=Mostcategories',
        interval => '*-16 01:00',
    }

    profile::mediawiki::periodic_job { 'updatequerypages_mostlinkedtemplates_s1':
        command  => '/usr/local/bin/mwscriptwikiset updateSpecialPages.php s1.dblist --override --only=Mostlinkedtemplates',
        interval => '*-18 01:00',
    }

    profile::mediawiki::periodic_job { 'updatequerypages_uncategorizedcategories_s1':
        command  => '/usr/local/bin/mwscriptwikiset updateSpecialPages.php s1.dblist --override --only=Uncategorizedcategories',
        interval => '*-19 01:00',
    }

    profile::mediawiki::periodic_job { 'updatequerypages_wantedtemplates_s1':
        command  => '/usr/local/bin/mwscriptwikiset updateSpecialPages.php s1.dblist --override --only=Wantedtemplates',
        interval => '*-20 01:00',
    }
}
