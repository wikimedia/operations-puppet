# a cronjob for updatequerypages
define mediawiki::maintenance::updatequerypages::cronjob( $ensure = $mediawiki::maintenance::updatequerypages::ensure ) {
        $db_cluster = regsubst($name, '@.*', '\1')
        # Currently they're all monthly, this part is kept for BC and in case we change mind
        # $monthday = regsubst($name, '.*@', '\1')

        Cron {
            ensure => $ensure,
            user   => $::mediawiki::users::web,
            hour   => 1,
            minute => 0,
            month  => absent,
        }

        cron { "cron-updatequerypages-ancientpages-${name}":
            command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${db_cluster}.dblist --override --only=Ancientpages > /var/log/mediawiki/updateSpecialPages/${name}-AncientPages.log 2>&1",
            monthday => [8, 22],
        }

        cron { "cron-updatequerypages-deadendpages-${name}":
            command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${db_cluster}.dblist --override --only=Deadendpages > /var/log/mediawiki/updateSpecialPages/${name}-DeadendPages.log 2>&1",
            monthday => [9, 23],
        }

        cron { "cron-updatequerypages-mostlinked-${name}":
            command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${db_cluster}.dblist --override --only=Mostlinked > /var/log/mediawiki/updateSpecialPages/${name}-MostLinked.log 2>&1",
            monthday => [10, 24],
        }

        cron { "cron-updatequerypages-mostrevisions-${name}":
            command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${db_cluster}.dblist --override --only=Mostrevisions > /var/log/mediawiki/updateSpecialPages/${name}-MostRevisions.log 2>&1",
            monthday => [11, 25],
        }

        cron { "cron-updatequerypages-wantedpages-${name}":
            command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${db_cluster}.dblist --override --only=Wantedpages > /var/log/mediawiki/updateSpecialPages/${name}-WantedPages.log 2>&1",
            monthday => [12, 26],
        }

        cron { "cron-updatequerypages-fewestrevisions-${name}":
            command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${db_cluster}.dblist --override --only=Fewestrevisions > /var/log/mediawiki/updateSpecialPages/${name}-FewestRevisions.log 2>&1",
            monthday => [13, 27],
        }
}
