# misc/maintenance.pp

########################################################################
#
# Maintenance scripts should always run as apache and never as mwdeploy.
#
# This is 1) for security reasons and 2) for consistent file ownership
# (if MediaWiki creates (temporary) files, they must be owned by apache)
#
########################################################################

class misc::maintenance::refreshlinks( $ensure = present ) {

    require mediawiki

    # Include this to add cron jobs calling refreshLinks.php on all clusters. (RT-2355)

    file { [ '/var/log/mediawiki/refreshLinks' ]:
        ensure => ensure_directory($ensure),
        owner  => $::mediawiki::users::web,
        group  => 'mwdeploy',
        mode   => '0664',
    }

    define cronjob( $ensure = present ) {
        $db_cluster = regsubst($name, '@.*', '\1')
        $monthday = regsubst($name, '.*@', '\1')

        cron { "cron-refreshlinks-${name}":
            ensure   => $ensure,
            command  => "/usr/local/bin/mwscriptwikiset refreshLinks.php ${db_cluster}.dblist --dfn-only > /var/log/mediawiki/refreshLinks/${name}.log 2>&1",
            user     => $::mediawiki::users::web,
            hour     => 0,
            minute   => 0,
            monthday => $monthday,
        }
    }

    # add cron jobs - usage: <cluster>@<day of month> (these are just needed monthly) (note: s1 is temp. deactivated)
    cronjob { ['s2@2', 's3@3', 's4@4', 's5@5', 's6@6', 's7@7']: }
}

class misc::maintenance::pagetriage( $ensure = present ) {

    require mediawiki

    system::role { 'misc::maintenance::pagetriage': description => 'Misc - Maintenance Server: pagetriage extension' }

    cron { 'pagetriage_cleanup_en':
        ensure   => $ensure,
        user     => $::mediawiki::users::web,
        minute   => 55,
        hour     => 20,
        monthday => '*/2',
        command  => '/usr/local/bin/mwscript extensions/PageTriage/cron/updatePageTriageQueue.php enwiki > /var/log/mediawiki/updatePageTriageQueue.en.log',
    }

    cron { 'pagetriage_cleanup_testwiki':
        ensure   => $ensure,
        user     => $::mediawiki::users::web,
        minute   => 55,
        hour     => 14,
        monthday => '*/2',
        command  => '/usr/local/bin/mwscript extensions/PageTriage/cron/updatePageTriageQueue.php testwiki > /var/log/mediawiki/updatePageTriageQueue.test.log',
    }
}

class misc::maintenance::translationnotifications( $ensure = present ) {
    # Should there be crontab entry for each wiki,
    # or just one which runs the scripts which iterates over
    # selected set of wikis?

    cron { 'translationnotifications-metawiki':
        ensure  => $ensure,
        user    => $::mediawiki::users::web,
        command => '/usr/local/bin/mwscript extensions/TranslationNotifications/scripts/DigestEmailer.php --wiki metawiki 2>&1 >> /var/log/translationnotifications/digests.log',
        weekday => 1, # Monday
        hour    => 10,
        minute  => 0,
    }

    cron { 'translationnotifications-mediawikiwiki':
        ensure  => $ensure,
        user    => $::mediawiki::users::web,
        command => '/usr/local/bin/mwscript extensions/TranslationNotifications/scripts/DigestEmailer.php --wiki mediawikiwiki 2>&1 >> /var/log/translationnotifications/digests.log',
        weekday => 1, # Monday
        hour    => 10,
        minute  => 5,
    }

    file { '/var/log/translationnotifications':
        ensure => ensure_directory($ensure),
        owner  => $::mediawiki::users::web,
        group  => 'wikidev',
        mode   => '0664',
    }

    file { '/etc/logrotate.d/l10nupdate':
        ensure => $ensure,
        source => 'puppet:///files/logrotate/translationnotifications',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
}

class misc::maintenance::tor_exit_node( $ensure = present ) {
    cron { 'tor_exit_node_update':
        ensure  => $ensure,
        command => '/usr/local/bin/mwscript extensions/TorBlock/loadExitNodes.php --wiki=aawiki --force > /dev/null',
        user    => $::mediawiki::users::web,
        minute  => '*/20',
    }
}

class misc::maintenance::echo_mail_batch( $ensure = present ) {
    cron { 'echo_mail_batch':
        ensure  => $ensure,
        command => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/echowikis.dblist extensions/Echo/maintenance/processEchoEmailBatch.php >/dev/null',
        user    => $::mediawiki::users::web,
        minute  => 0,
        hour    => 0,
    }
}

class misc::maintenance::update_flaggedrev_stats( $ensure = present ) {
    file { '/srv/mediawiki/php/extensions/FlaggedRevs/maintenance/wikimedia-periodic-update.sh':
        ensure => $ensure,
        source => 'puppet:///files/misc/scripts/wikimedia-periodic-update.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    cron { 'update_flaggedrev_stats':
        ensure  => $ensure,
        command => '/srv/mediawiki/php/extensions/FlaggedRevs/maintenance/wikimedia-periodic-update.sh > /dev/null',
        user    => $::mediawiki::users::web,
        hour    => '*/2',
        minute  => '0',
    }
}

class misc::maintenance::cleanup_upload_stash( $ensure = present ) {
    cron { 'cleanup_upload_stash':
        ensure  => $ensure,
        command => '/usr/local/bin/foreachwiki maintenance/cleanupUploadStash.php > /dev/null',
        user    => $::mediawiki::users::web,
        hour    => 1,
        minute  => 0,
    }
}

class misc::maintenance::update_special_pages( $ensure = present ) {
    cron { 'update_special_pages':
        ensure   => $ensure,
        command  => 'flock -n /var/lock/update-special-pages /usr/local/bin/update-special-pages > /var/log/mediawiki/updateSpecialPages.log 2>&1',
        user     => $::mediawiki::users::web,
        monthday => '*/3',
        hour     => 5,
        minute   => 0,
    }

    file { '/usr/local/bin/update-special-pages':
        ensure => $ensure,
        source => 'puppet:///files/misc/scripts/update-special-pages',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}

class misc::maintenance::update_article_count( $ensure = present ) {
    cron { 'update_article_count':
        ensure   => $ensure,
        command  => 'flock -n /var/lock/update-article-count /usr/local/bin/update-article-count > /var/log/mediawiki/updateArticleCount.log 2>&1',
        user     => $::mediawiki::users::web,
        monthday => 21,
        hour     => 5,
        minute   => 0,
    }

    file { '/usr/local/bin/update-article-count':
        ensure => $ensure,
        source => 'puppet:///files/misc/scripts/update-article-count',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}

class misc::maintenance::wikidata( $ensure = present ) {
    require mediawiki::users

    # Starts a dispatcher instance every 3 minutes
    # This handles inserting jobs into client job queue, which then process the changes
    cron { 'wikibase-dispatch-changes4':
        ensure  => $ensure,
        command => '/usr/local/bin/mwscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/dispatchChanges.php --wiki wikidatawiki --max-time 1400 --batch-size 250 --dispatch-interval 25 2>&1 >> /dev/null',
        user    => $::mediawiki::users::web,
        minute  => '*/3',
    }

    cron { 'wikibase-dispatch-changes-test':
        ensure  => $ensure,
        command => '/usr/local/bin/mwscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/dispatchChanges.php --wiki testwikidatawiki --max-time 900 --batch-size 200 --dispatch-interval 30 2>&1 >> /dev/null',
        user    => $::mediawiki::users::web,
        minute  => '*/15',
    }

    # Prune wb_changes entries no longer needed from (test)wikidata
    cron { 'wikibase-repo-prune2':
        ensure  => $ensure,
        command => '/usr/local/bin/mwscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/pruneChanges.php --wiki wikidatawiki --number-of-days=3 2>&1 >> /var/log/wikidata/prune2.log',
        user    => $::mediawiki::users::web,
        minute  => [0,15,30,45],
    }

    cron { 'wikibase-repo-prune-test':
        ensure  => $ensure,
        command => '/usr/local/bin/mwscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/pruneChanges.php --wiki testwikidatawiki --number-of-days=3 2>&1 >> /var/log/wikidata/prune-testwikidata.log',
        user    => $::mediawiki::users::web,
        minute  => [0,15,30,45],
    }

    # Run the rebuildEntityPerPage script once a week to fix broken wb_entity_per_page entries
    cron { 'wikibase-rebuild-entityperpage':
        ensure  => $ensure,
        command => '/usr/local/bin/mwscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/rebuildEntityPerPage.php --wiki wikidatawiki --force 2>&1 >> /var/log/wikidata/rebuildEpp.log',
        user    => $::mediawiki::users::web,
        minute  => 30,
        hour    => 3,
        weekday => 0,
    }

    file { '/var/log/wikidata':
        ensure => ensure_directory($ensure),
        owner  => $::mediawiki::users::web,
        group  => $::mediawiki::users::web,
        mode   => '0664',
    }

    file { '/etc/logrotate.d/wikidata':
        ensure => $ensure,
        source => 'puppet:///files/logrotate/wikidata',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
}

class misc::maintenance::parsercachepurging( $ensure = present ) {

    system::role { 'misc::maintenance::parsercachepurging': description => 'Misc - Maintenance Server: parser cache purging' }

    cron { 'parser_cache_purging':
        ensure  => $ensure,
        user    => $::mediawiki::users::web,
        minute  => 0,
        hour    => 1,
        weekday => 0,
        # Purge entries older than 30d * 86400s/d = 2592000s
        command => '/usr/local/bin/mwscript purgeParserCache.php --wiki=aawiki --age=2592000 >/dev/null 2>&1',
    }
}

class misc::maintenance::updatetranslationstats( $ensure = present ) {
    # Include this to a maintenance host to update translation stats.

    file { '/usr/local/bin/characterEditStatsTranslate':
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///files/misc/scripts/characterEditStatsTranslate',
    }

    cron { 'updatetranslationstats':
        ensure  => $ensure,
        user    => $::mediawiki::users::web,
        minute  => 0,
        hour    => 0,
        weekday => 1,
        command => '/usr/local/bin/characterEditStatsTranslate >/dev/null',
    }
}

class misc::maintenance::updatequerypages( $ensure = present ) {
        # Include this to add cron jobs calling updateSpecialPages.php on all clusters.

        file { '/var/log/mediawiki/updateSpecialPages':
                ensure => directory,
                owner  => $::mediawiki::users::web,
                group  => 'mwdeploy',
                mode   => '0664',
        }

        define updatequerypages::cronjob( $ensure = $misc::maintenance::updatequerypages::ensure ) {
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

        define updatequerypages::enwiki::cronjob() {
            $ensure = $misc::maintenance::updatequerypages::status

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
        updatequerypages::cronjob { ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17']: }
        updatequerypages::enwiki::cronjob { ['updatequerypages-enwiki-only']: }
}

class misc::maintenance::purge_abusefilter( $ensure = present ) {
    cron { 'purge_abusefilteripdata':
        ensure  => $ensure,
        command => '/usr/local/bin/foreachwiki extensions/AbuseFilter/maintenance/purgeOldLogIPData.php >/dev/null 2>&1',
        user    => $::mediawiki::users::web,
        hour    => '1',
    }
}

class misc::maintenance::purge_checkuser( $ensure = present ) {
    cron { 'purge-checkuser':
        ensure  => $ensure,
        user    => $::mediawiki::users::web,
        minute  => 0,
        hour    => 0,
        weekday => 0,
        command => '/usr/local/bin/foreachwiki extensions/CheckUser/maintenance/purgeOldData.php 2>&1 > /dev/null',
    }
}

class misc::maintenance::purge_securepoll( $ensure = present ) {
    cron { 'purge_securepollvotedata':
        ensure  => $ensure,
        user    => $::mediawiki::users::web,
        hour    => '1',
        command => '/usr/local/bin/foreachwiki extensions/SecurePoll/cli/purgePrivateVoteData.php 2>&1 > /dev/null',
    }
}
