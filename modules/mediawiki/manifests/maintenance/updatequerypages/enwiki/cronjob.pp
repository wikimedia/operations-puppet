# a cronjob for updatequerypages for enwiki
define mdeiawiki::maintenance::updatequerypages::enwiki::cronjob($ensure = $mediawiki::maintenance::updatequerypages::ensure) {


    Cron {
        ensure => $ensure,
        user   => $::mediawiki::users::web,
        hour   => 1,
        minute => 0,
    }

    cron { 'cron-updatequerypages-lonelypages-s1':
        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php s1.dblist --override --only=Lonelypages > /var/log/mediawiki/updateSpecialPages/${name}-LonelyPages.log 2>&1",
        month    => [1, 7],
        monthday => 28,
    }

    cron { 'cron-updatequerypages-mostcategories-s1':
        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php s1.dblist --override --only=Mostcategories > /var/log/mediawiki/updateSpecialPages/${name}-MostCategories.log 2>&1",
        month    => [2, 8],
        monthday => 28,
    }

    cron { 'cron-updatequerypages-mostlinkedcategories-s1':
        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php s1.dblist --override --only=Mostlinkedcategories > /var/log/mediawiki/updateSpecialPages/${name}-MostLinkedCategories.log 2>&1",
        month    => [3, 9],
        monthday => 28,
    }

    cron { 'cron-updatequerypages-mostlinkedtemplates-s1':
        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php s1.dblist --override --only=Mostlinkedtemplates > /var/log/mediawiki/updateSpecialPages/${name}-MostLinkedTemplates.log 2>&1",
        month    => [4, 10],
        monthday => 28,
    }

    cron { 'cron-updatequerypages-uncategorizedcategories-s1':
        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php s1.dblist --override --only=Uncategorizedcategories > /var/log/mediawiki/updateSpecialPages/${name}-UncategorizedCategories.log 2>&1",
        month    => [5, 11],
        monthday => 28,
    }

    cron { 'cron-updatequerypages-wantedtemplates-s1':
        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php s1.dblist --override --only=Wantedtemplates > /var/log/mediawiki/updateSpecialPages/${name}-WantedTemplates.log 2>&1",
        month    => [6, 12],
        monthday => 28,
    }
}
