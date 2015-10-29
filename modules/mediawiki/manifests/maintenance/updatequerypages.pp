class mediawiki::maintenance::updatequerypages( $ensure = present ) {
        # Include this to add cron jobs calling updateSpecialPages.php on all clusters.

        file { '/var/log/mediawiki/updateSpecialPages':
                ensure => directory,
                owner  => $::mediawiki::users::web,
                group  => 'mwdeploy',
                mode   => '0664',
        }

        define updatequerypages::cronjob( $ensure = $mediawiki::maintenance::updatequerypages::ensure ) {
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

        define updatequerypages::enwiki::cronjob($ensure = $mediawiki::maintenance::updatequerypages::ensure) {


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

        # add cron jobs - usage: <cluster>@<day of month> (monthday currently unused, only sets cronjob name)
        updatequerypages::cronjob { ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17', 'silver@18']: }
        updatequerypages::enwiki::cronjob { ['updatequerypages-enwiki-only']: }
}
