class mediawiki::maintenance::wikidata( $ensure = present ) {
    require mediawiki::users

    # Starts a dispatcher instance every 3 minutes
    # This handles inserting jobs into client job queue, which then process the changes
    cron { 'wikibase-dispatch-changes4':
        ensure  => $ensure,
        command => '/usr/bin/run-one /usr/local/bin/mwscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/dispatchChanges.php --wiki wikidatawiki --max-time 1600 --batch-size 275 --dispatch-interval 25 --lock-grace-interval 200 2>&1 >> /dev/null',
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
        source => 'puppet:///modules/mediawiki/maintenance/logrotate.d_wikidata',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
}
