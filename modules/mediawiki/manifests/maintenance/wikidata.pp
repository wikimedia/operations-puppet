class mediawiki::maintenance::wikidata( $ensure = present ) {
    require ::mediawiki::users

    file { '/var/log/wikidata':
        ensure => ensure_directory($ensure),
        owner  => $::mediawiki::users::web,
        group  => $::mediawiki::users::web,
        mode   => '0664',
    }

    # Starts a dispatcher instance every 3 minutes
    # They will run for a maximum of 9 minutes, so we can only have 3 concurrent instances.
    # This handles inserting jobs into client job queue, which then process the changes
    cron { 'wikibase-dispatch-changes4':
        ensure  => $ensure,
        command => '/usr/local/bin/mwscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/dispatchChanges.php --wiki wikidatawiki --max-time 540 --batch-size 420 --dispatch-interval 25 --lock-grace-interval 200 >/dev/null 2>&1',
        user    => $::mediawiki::users::web,
        minute  => '*/3',
    }

    cron { 'wikibase-dispatch-changes-test':
        ensure  => $ensure,
        command => '/usr/local/bin/mwscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/dispatchChanges.php --wiki testwikidatawiki --max-time 900 --batch-size 200 --dispatch-interval 30 >/dev/null 2>&1',
        user    => $::mediawiki::users::web,
        minute  => '*/15',
    }

    $pruneLogFile = "/var/log/wikidata/prune2.log"
    file { $pruneLogFile:
        ensure  => 'file',
        owner   => $::mediawiki::users::web,
        group   => $::mediawiki::users::web,
        mode    => '0664',
        require => File['/var/log/wikidata'],
    }

    # Prune wb_changes entries no longer needed from (test)wikidata
    cron { 'wikibase-repo-prune2':
        ensure  => $ensure,
        command => "/usr/local/bin/mwscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/pruneChanges.php --wiki wikidatawiki --number-of-days=3 >> ${$pruneLogFile} 2>&1",
        user    => $::mediawiki::users::web,
        minute  => [0,15,30,45],
        require => File[$pruneLogFile],
    }

    $testPruneLogFile = "/var/log/wikidata/prune-testwikidata.log"
    file { $testPruneLogFile:
        ensure  => 'file',
        owner   => $::mediawiki::users::web,
        group   => $::mediawiki::users::web,
        mode    => '0664',
        require => File['/var/log/wikidata'],
    }

    cron { 'wikibase-repo-prune-test':
        ensure  => $ensure,
        command => "/usr/local/bin/mwscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/pruneChanges.php --wiki testwikidatawiki --number-of-days=3 >> ${testPruneLogFile} 2>&1",
        user    => $::mediawiki::users::web,
        minute  => [0,15,30,45],
        require => File[$testPruneLogFile],
    }

    $rebuildTermSqlIndexLogFile = '/var/log/wikidata/rebuildTermSqlIndex.log'
    file { $rebuildTermSqlIndexLogFile:
        ensure  => 'file',
        owner   => $::mediawiki::users::web,
        group   => $::mediawiki::users::web,
        mode    => '0664',
        require => File['/var/log/wikidata'],
    }

    $log_ownership_user = $::mediawiki::users::web
    $log_ownership_group = $::mediawiki::users::web
    logrotate::conf { 'wikidata':
        ensure  => $ensure,
        content => template('mediawiki/maintenance/logrotate.d_wikidata.erb'),
    }

    # rebuildTermSqlIndex is temporarily stopped
    cron { 'wikibase-rebuildTermSqlIndex':
        ensure  => absent,
        command => "/usr/bin/timeout 3500s /usr/local/bin/mwscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/rebuildTermSqlIndex.php --wiki wikidatawiki --entity-type=item --deduplicate-terms --batch-size 500 --sleep 10 --from-id $(/bin/ls -t ${rebuildTermSqlIndexLogFile} ${rebuildTermSqlIndexLogFile}*[0-9] | /usr/bin/xargs -d \"\n\" /usr/bin/tac 2> /dev/null | /usr/bin/awk \'/Processed up to page (\d+?)/ { print $5 }\' | head -n1) >> ${rebuildTermSqlIndexLogFile} 2>&1",
        user    => $::mediawiki::users::web,
        minute  => 30,
        hour    => '*',
        weekday => '*',
        require => File[$rebuildTermSqlIndexLogFile],
    }
}
