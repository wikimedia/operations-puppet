# misc/maintenance.pp

########################################################################
#
# Maintenance scripts should always run as apache and never as mwdeploy.
#
# This is 1) for security reasons and 2) for consistent file ownership
# (if MediaWiki creates (temporary) files, they must be owned by apache)
#
########################################################################

class misc::maintenance::refreshlinks( $enabled = false ) {

    require mediawiki

    # Include this to add cron jobs calling refreshLinks.php on all clusters. (RT-2355)

    if $enabled == true {
        file { [ '/var/log/mediawiki/refreshLinks' ]:
            ensure => directory,
            owner  => 'apache',
            group  => 'mwdeploy',
            mode   => '0664',
        }
    }

    define cronjob( $cronenabled = $misc::maintenance::refreshlinks::enabled ) {

        $cluster = regsubst($name, '@.*', '\1')
        $monthday = regsubst($name, '.*@', '\1')

        cron { "cron-refreshlinks-${name}":
            command  => "/usr/local/bin/mwscriptwikiset refreshLinks.php ${cluster}.dblist --dfn-only > /var/log/mediawiki/refreshLinks/${name}.log 2>&1",
            user     => 'apache',
            hour     => 0,
            minute   => 0,
            monthday => $monthday,
            ensure   => $cronenabled ?{
                true    => present,
                false   => absent,
                default => absent
            };
        }
    }

    # add cron jobs - usage: <cluster>@<day of month> (these are just needed monthly) (note: s1 is temp. deactivated)
    cronjob { ['s2@2', 's3@3', 's4@4', 's5@5', 's6@6', 's7@7']: }
}

class misc::maintenance::pagetriage( $enabled = false ) {

    system::role { 'misc::maintenance::pagetriage': description => 'Misc - Maintenance Server: pagetriage extension' }

    cron { 'pagetriage_cleanup_en':
        user     => apache,
        minute   => 55,
        hour     => 20,
        monthday => '*/2',
        command  => '/usr/local/bin/mwscript extensions/PageTriage/cron/updatePageTriageQueue.php enwiki > /var/log/mediawiki/updatePageTriageQueue.en.log',
        ensure   => $enabled ?{
            true    => present,
            false   => absent,
            default => absent
        };
    }

    cron { 'pagetriage_cleanup_testwiki':
        user     => apache,
        minute   => 55,
        hour     => 14,
        monthday => '*/2',
        command  => '/usr/local/bin/mwscript extensions/PageTriage/cron/updatePageTriageQueue.php testwiki > /var/log/mediawiki/updatePageTriageQueue.test.log',
        ensure   => $enabled ?{
            true    => present,
            false   => absent,
            default => absent
        };
    }
}

class misc::maintenance::translationnotifications( $enabled = false ) {
    # Should there be crontab entry for each wiki,
    # or just one which runs the scripts which iterates over
    # selected set of wikis?

    cron {
        'translationnotifications-metawiki':
            user    => 'apache',
            command => '/usr/local/bin/mwscript extensions/TranslationNotifications/scripts/DigestEmailer.php --wiki metawiki 2>&1 >> /var/log/mediawiki/translationnotifications/digests.log',
            weekday => 1, # Monday
            hour    => 10,
            minute  => 0,
            ensure  => $enabled ?{
                true    => present,
                false   => absent,
                default => absent
            };

        'translationnotifications-mediawikiwiki':
            user    => 'apache',
            command => '/usr/local/bin/mwscript extensions/TranslationNotifications/scripts/DigestEmailer.php --wiki mediawikiwiki 2>&1 >> /var/log/mediawiki/translationnotifications/digests.log',
            weekday => 1, # Monday
            hour    => 10,
            minute  => 5,
            ensure  => $enabled ?{
                true    => present,
                false   => absent,
                default => absent
            };
    }

    file {
        '/var/log/translationnotifications':
            owner  => 'apache',
            group  => 'wikidev',
            mode   => '0664',
            ensure => directory;
        '/etc/logrotate.d/l10nupdate':
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => 'puppet:///files/logrotate/translationnotifications',
    }
}

class misc::maintenance::tor_exit_node( $enabled = false ) {
    cron {
        'tor_exit_node_update':
            command => '/usr/local/bin/mwscript extensions/TorBlock/loadExitNodes.php --wiki=aawiki --force > /dev/null',
            user    => 'apache',
            minute  => '*/20',
            ensure  => $enabled ?{
                true    => present,
                false   => absent,
                default => absent
            };
    }
}

class misc::maintenance::echo_mail_batch( $enabled = false ) {
    cron {
        'echo_mail_batch':
            command => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/echowikis.dblist extensions/Echo/maintenance/processEchoEmailBatch.php 2>/dev/null',
            user    => 'apache',
            minute  => 0,
            hour    => 0,
            ensure  => $enabled ?{
                true    => present,
                false   => absent,
                default => absent
            };
    }
}

class misc::maintenance::update_flaggedrev_stats( $enabled = false ) {
    file {
        '/srv/mediawiki/php/extensions/FlaggedRevs/maintenance/wikimedia-periodic-update.sh':
            source => 'puppet:///files/misc/scripts/wikimedia-periodic-update.sh',
            owner  => 'apache',
            group  => 'wikidev',
            mode   => '0755',
            ensure => present;
    }

    cron {
        'update_flaggedrev_stats':
            command => '/srv/mediawiki/php/extensions/FlaggedRevs/maintenance/wikimedia-periodic-update.sh > /dev/null',
            user    => 'apache',
            hour    => '*/2',
            minute  => '0',
            ensure  => $enabled ?{
                true    => present,
                false   => absent,
                default => absent
            };
    }
}

class misc::maintenance::cleanup_upload_stash( $enabled = false ) {
    cron {
        'cleanup_upload_stash':
            command => '/usr/local/bin/foreachwiki maintenance/cleanupUploadStash.php > /dev/null',
            user    => 'apache',
            hour    => 1,
            minute  => 0,
            ensure  => $enabled ?{
                true    => present,
                false   => absent,
                default => absent
            };
    }
}

class misc::maintenance::update_special_pages( $enabled = false ) {
    cron {
        'update_special_pages':
            command  => 'flock -n /var/lock/update-special-pages /usr/local/bin/update-special-pages > /var/log/mediawiki/updateSpecialPages.log 2>&1',
            user     => 'apache',
            monthday => '*/3',
            hour     => 5,
            minute   => 0,
            ensure   => $enabled ?{
                true    => present,
                false   => absent,
                default => absent
            };
        'update_special_pages_small':
            ensure => absent;
    }

    file {
        '/usr/local/bin/update-special-pages':
            source => 'puppet:///files/misc/scripts/update-special-pages',
            owner  => 'apache',
            group  => 'wikidev',
            mode   => '0755',
            ensure => present;
        '/usr/local/bin/update-special-pages-small':
            ensure => absent;
    }
}

class misc::maintenance::wikidata( $enabled = false ) {

    $wbenabled = $enabled ? {
        true    => 'present',
        false   => 'absent',
        default => 'absent',
    }

    cron { 'wikibase-repo-prune2':
        # prunes the wb_changes table in wikidatawiki db
        command => '/usr/local/bin/mwscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/pruneChanges.php --wiki wikidatawiki --number-of-days=3 2>&1 >> /var/log/wikidata/prune2.log',
        user    => 'apache',
        minute  => [0,15,30,45],
        ensure  => $wbenabled,
    }

    # Run the dispatcher script every 5 minutes
    # This handles inserting jobs into client job queue, which then process the changes
    cron { 'wikibase-dispatch-changes3':
        # dispatches changes data to wikibase clients (e.g. wikipedia) to be processed as jobs there
        command => '/usr/local/bin/mwscript extensions/Wikidata/extensions/Wikibase/lib/maintenance/dispatchChanges.php --wiki wikidatawiki --max-time 900 --batch-size 200 --dispatch-interval 30 2>&1 >> /var/log/wikidata/dispatcher3.log',
        user    => 'apache',
        minute  => '*/5',
        ensure  => $wbenabled,
    }

    cron { 'wikibase-dispatch-changes4':
        # second dispatcher to inject wikidata changes  wikibase clients (e.g. wikipedia) to be processed as jobs there
        command => '/usr/local/bin/mwscript extensions/Wikidata/extensions/Wikibase/lib/maintenance/dispatchChanges.php --wiki wikidatawiki --max-time 900 --batch-size 200 --dispatch-interval 30 2>&1 >> /var/log/wikidata/dispatcher4.log',
        user    => 'apache',
        minute  => '*/5',
        ensure  => $wbenabled,
    }

    cron { 'wikibase-rebuild-entityperpage':
        command  => '/usr/local/bin/mwscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/rebuildEntityPerPage.php --wiki wikidatawiki --force 2>&1 >> /var/log/wikidata/rebuildEpp.log',
        user     => 'apache',
        minute   => 30,
        hour     => 3,
        weekday  => 0,
        ensure   => $wbenabled,
    }

    file {
        '/var/log/wikidata':
            owner  => 'apache',
            group  => 'apache',
            mode   => '0664',
            ensure => directory;
        '/etc/logrotate.d/wikidata':
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => 'puppet:///files/logrotate/wikidata',
    }
}

class misc::maintenance::parsercachepurging( $enabled = false ) {

    system::role { 'misc::maintenance::parsercachepurging': description => 'Misc - Maintenance Server: parser cache purging' }

    cron { 'parser_cache_purging':
        user    => 'apache',
        minute  => 0,
        hour    => 1,
        weekday => 0,
        # Purge entries older than 30d * 86400s/d = 2592000s
        command => '/usr/local/bin/mwscript purgeParserCache.php --wiki=aawiki --age=2592000 >/dev/null 2>&1',
        ensure  => $enabled ?{
            true    => present,
            false   => absent,
            default => absent
        };
    }

}

class misc::maintenance::updatetranslationstats( $ensure = absent ) {
    # Include this to a maintenance host to update translation stats.

    file { '/usr/local/bin/characterEditStatsTranslate':
       ensure => $ensure,
       owner  => 'mwdeploy',
       group  => 'mwdeploy',
       mode   => '0775',
       source => 'puppet:///files/misc/scripts/characterEditStatsTranslate',
    }
    cron { 'updatetranslationstats':
        user    => 'apache',
        minute  => 0,
        hour    => 0,
        weekday => 1,
        command => '/usr/local/bin/characterEditStatsTranslate',
        ensure  => $ensure,
    }
}

class misc::maintenance::updatequerypages( $enabled = false ) {
        # Include this to add cron jobs calling updateSpecialPages.php on all clusters.

        file { '/var/log/mediawiki/updateSpecialPages':
                ensure => directory,
                owner  => 'apache',
                group  => 'mwdeploy',
                mode   => '0664',
        }
        $status = $enabled ?{
            true    => present,
            false   => absent,
            default => absent
        }

        define updatequerypages::cronjob(
            $status = $misc::maintenance::updatequerypages::status
            ) {
                $cluster = regsubst($name, '@.*', '\1')
                # Currently they're all monthly, this part is kept for BC and in case we change mind
                # $monthday = regsubst($name, '.*@', '\1')

                Cron {
                        user   => 'apache',
                        hour   => 1,
                        minute => 0,
                        month  => absent,
                }

                cron { "cron-updatequerypages-ancientpages-${name}":
                        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${cluster}.dblist --override --only=Ancientpages > /var/log/mediawiki/updateSpecialPages/${name}-AncientPages.log 2>&1",
                        monthday => 11,
                        ensure   => $status
                }

                cron { "cron-updatequerypages-deadendpages-${name}":
                        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${cluster}.dblist --override --only=Deadendpages > /var/log/mediawiki/updateSpecialPages/${name}-DeadendPages.log 2>&1",
                        monthday => 12,
                    ensure       => $status
                }

                cron { "cron-updatequerypages-mostlinked-${name}":
                        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${cluster}.dblist --override --only=Mostlinked > /var/log/mediawiki/updateSpecialPages/${name}-MostLinked.log 2>&1",
                        monthday => 13,
                    ensure       => $status
                }

                cron { "cron-updatequerypages-mostrevisions-${name}":
                        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${cluster}.dblist --override --only=Mostrevisions > /var/log/mediawiki/updateSpecialPages/${name}-MostRevisions.log 2>&1",
                        monthday => 14,
                        ensure   => $status
                }

                cron { "cron-updatequerypages-wantedpages-${name}":
                        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${cluster}.dblist --override --only=Wantedpages > /var/log/mediawiki/updateSpecialPages/${name}-WantedPages.log 2>&1",
                        monthday => 15,
                        ensure   => $status
                }

                cron { "cron-updatequerypages-fewestrevisions-${name}":
                        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php ${cluster}.dblist --override --only=Fewestrevisions > /var/log/mediawiki/updateSpecialPages/${name}-FewestRevisions.log 2>&1",
                        monthday => 16,
                        ensure   => $status
                }
        }

        define updatequerypages::enwiki::cronjob() {
            $status = $misc::maintenance::updatequerypages::status
                Cron {
                        user   => 'apache',
                        hour   => 1,
                        minute => 0,
                }

                cron { 'cron-updatequerypages-lonelypages-s1':
                        command   => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php s1.dblist --override --only=Lonelypages > /var/log/mediawiki/updateSpecialPages/${name}-LonelyPages.log 2>&1",
                        month     => [1, 7],
                        monthday  => 18,
                        ensure    => $status
                }

                cron { 'cron-updatequerypages-mostcategories-s1':
                        command   => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php s1.dblist --override --only=Mostcategories > /var/log/mediawiki/updateSpecialPages/${name}-MostCategories.log 2>&1",
                        month     => [2, 8],
                        monthday  => 19,
                        ensure    => $status
                }

                cron { 'cron-updatequerypages-mostlinkedcategories-s1':
                        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php s1.dblist --override --only=Mostlinkedcategories > /var/log/mediawiki/updateSpecialPages/${name}-MostLinkedCategories.log 2>&1",
                        month    => [3, 9],
                        monthday => 20,
                        ensure   => $status
                }

                cron { 'cron-updatequerypages-mostlinkedtemplates-s1':
                        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php s1.dblist --override --only=Mostlinkedtemplates > /var/log/mediawiki/updateSpecialPages/${name}-MostLinkedTemplates.log 2>&1",
                        month    => [4, 10],
                        monthday => 21,
                        ensure   => $status
                }

                cron { 'cron-updatequerypages-uncategorizedcategories-s1':
                        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php s1.dblist --override --only=Uncategorizedcategories > /var/log/mediawiki/updateSpecialPages/${name}-UncategorizedCategories.log 2>&1",
                        month    => [5, 11],
                        monthday => 22,
                        ensure   => $status
                }

                cron { 'cron-updatequerypages-wantedtemplates-s1':
                        command  => "/usr/local/bin/mwscriptwikiset updateSpecialPages.php s1.dblist --override --only=Wantedtemplates > /var/log/mediawiki/updateSpecialPages/${name}-WantedTemplates.log 2>&1",
                        month    => [6, 12],
                        monthday => 23,
                        ensure   => $status
                }
        }

        # add cron jobs - usage: <cluster>@<day of month> (monthday currently unused, only sets cronjob name)
        updatequerypages::cronjob { ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17']: }
        updatequerypages::enwiki::cronjob { ['updatequerypages-enwiki-only']: }
}

class misc::maintenance::purge_abusefilter( $enabled = false ) {

        $status = $enabled ? {
            true    => 'present',
            false   => 'absent',
            default => 'absent',
        }

        # Erroneously named version
        cron { 'purge_securepoll':
            ensure  => 'absent',
        }

        cron { 'purge_abusefilteripdata':
            command => '/usr/local/bin/foreachwiki extensions/AbuseFilter/maintenance/purgeOldLogIPData.php >/dev/null 2>&1',
            user    => 'apache',
            hour    => '1',
            ensure  => $status,
        }
}

class misc::maintenance::purge_checkuser( $enabled = false ) {
    $status = $enabled ? {
        true    => 'present',
        false   => 'absent',
        default => 'absent',
    }

    cron { 'purge-checkuser':
        ensure  => $status,
        user    => 'apache',
        minute  => 0,
        hour    => 0,
        weekday => 0,
        command => '/usr/local/bin/foreachwiki extensions/CheckUser/maintenance/purgeOldData.php 2>&1 > /dev/null',
    }
}

class misc::maintenance::purge_securepoll( $enabled = false ) {
    $status = $enabled ? {
        true    => 'present',
        false   => 'absent',
        default => 'absent',
    }

    cron { 'purge_securepollvotedata':
        ensure  => $status,
        user    => 'apache',
        hour    => '1',
        command => '/usr/local/bin/foreachwiki extensions/SecurePoll/cli/purgePrivateVoteData.php 2>&1 > /dev/null',
    }
}
