
class mediawiki::maintenance::wikidata( $ensure = present ) {
    require mediawiki::users

    cron { 'wikibase-repo-prune2':
        ensure  => $ensure,
        # prunes the wb_changes table in wikidatawiki db
        command => '/usr/local/bin/mwscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/pruneChanges.php --wiki wikidatawiki --number-of-days=3 2>&1 >> /var/log/wikidata/prune2.log',
        user    => $::mediawiki::users::web,
        minute  => [0,15,30,45],
    }

    # Run the dispatcher script every 5 minutes
    # This handles inserting jobs into client job queue, which then process the changes
    cron { 'wikibase-dispatch-changes3':
        ensure  => $ensure,
        # dispatches changes data to wikibase clients (e.g. wikipedia) to be processed as jobs there
        command => '/usr/local/bin/mwscript extensions/Wikidata/extensions/Wikibase/lib/maintenance/dispatchChanges.php --wiki wikidatawiki --max-time 900 --batch-size 200 --dispatch-interval 30 2>&1 >> /var/log/wikidata/dispatcher3.log',
        user    => $::mediawiki::users::web,
        minute  => '*/5',
    }

    cron { 'wikibase-dispatch-changes4':
        ensure  => $ensure,
        # second dispatcher to inject wikidata changes  wikibase clients (e.g. wikipedia) to be processed as jobs there
        command => '/usr/local/bin/mwscript extensions/Wikidata/extensions/Wikibase/lib/maintenance/dispatchChanges.php --wiki wikidatawiki --max-time 900 --batch-size 200 --dispatch-interval 30 2>&1 >> /var/log/wikidata/dispatcher4.log',
        user    => $::mediawiki::users::web,
        minute  => '*/5',
    }

    cron { 'wikibase-dispatch-changes-test':
        ensure  => $ensure,
        # second dispatcher to inject wikidata changes  wikibase clients (e.g. wikipedia) to be processed as jobs there
        command => '/usr/local/bin/mwscript extensions/Wikidata/extensions/Wikibase/lib/maintenance/dispatchChanges.php --wiki testwikidatawiki --max-time 900 --batch-size 200 --dispatch-interval 30 2>&1 >> /var/log/wikidata/dispatcher-testwikidata.log',
        user    => $::mediawiki::users::web,
        minute  => '*/5',
    }

    cron { 'wikibase-repo-prune-test':
        ensure  => $ensure,
        # prunes the wb_changes table in testwikidatawiki db
        command => '/usr/local/bin/mwscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/pruneChanges.php --wiki testwikidatawiki --number-of-days=3 2>&1 >> /var/log/wikidata/prune-testwikidata.log',
        user    => $::mediawiki::users::web,
        minute  => [0,15,30,45],
    }

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

