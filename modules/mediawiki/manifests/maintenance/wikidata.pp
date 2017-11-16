class mediawiki::maintenance::wikidata( $ensure = present, $ensureTestwiki = present ) {
    require ::mediawiki::users

    # Starts a dispatcher instance every 3 minutes
    # They will run for a maximum of 9 minutes, so we can only have 3 concurrent instances.
    # This handles inserting jobs into client job queue, which then process the changes
    $dispatch_log_file = '/var/log/wikidata/dispatchChanges-wikidatawiki.log';
    cron { 'wikibase-dispatch-changes4':
        ensure  => $ensure,
        command => "echo \"\$\$: Starting dispatcher\" >> ${dispatch_log_file}; /usr/local/bin/mwscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/dispatchChanges.php --wiki wikidatawiki --max-time 540 --batch-size 420 --dispatch-interval 25 --lock-grace-interval 200 >> ${dispatch_log_file} 2>&1; echo \"\$\$: Dispatcher exited with $?\" >> ${dispatch_log_file}",
        user    => $::mediawiki::users::web,
        minute  => '*/3',
        require => File['/var/log/wikidata'],
    }

    cron { 'wikibase-dispatch-changes-test':
        ensure  => $ensureTestwiki,
        command => '/usr/local/bin/mwscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/dispatchChanges.php --wiki testwikidatawiki --max-time 900 --batch-size 200 --dispatch-interval 30 >/dev/null 2>&1',
        user    => $::mediawiki::users::web,
        minute  => '*/15',
    }

    # Prune wb_changes entries no longer needed from (test)wikidata
    cron { 'wikibase-repo-prune2':
        ensure  => $ensure,
        command => '/usr/local/bin/mwscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/pruneChanges.php --wiki wikidatawiki --number-of-days=3 >> /var/log/wikidata/prune2.log 2>&1',
        user    => $::mediawiki::users::web,
        minute  => [0,15,30,45],
        require => File['/var/log/wikidata'],
    }

    cron { 'wikibase-repo-prune-test':
        ensure  => $ensureTestwiki,
        command => '/usr/local/bin/mwscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/pruneChanges.php --wiki testwikidatawiki --number-of-days=3 >> /var/log/wikidata/prune-testwikidata.log 2>&1',
        user    => $::mediawiki::users::web,
        minute  => [0,15,30,45],
        require => File['/var/log/wikidata'],
    }

    file { '/var/log/wikidata':
        ensure => ensure_directory($ensure),
        owner  => $::mediawiki::users::web,
        group  => $::mediawiki::users::web,
        mode   => '0664',
    }

    file { '/var/log/wikidata/rebuildTermSqlIndex.log':
        ensure => 'file',
        owner  => $::mediawiki::users::web,
        group  => $::mediawiki::users::web,
        mode   => '0664',
    }

    $log_ownership_user = $::mediawiki::users::web
    $log_ownership_group = $::mediawiki::users::web
    logrotate::conf { 'wikidata':
        ensure  => $ensure,
        content => template('mediawiki/maintenance/logrotate.d_wikidata.erb'),
    }

    # rebuildTermSqlIndex is temporarilly stopped
    cron { 'wikibase-rebuildTermSqlIndex':
        ensure  => absent,
        command => '/usr/bin/timeout 3500s /usr/local/bin/mwscript extensions/Wikidata/extensions/Wikibase/repo/maintenance/rebuildTermSqlIndex.php --wiki wikidatawiki --entity-type=item --deduplicate-terms --batch-size 500 --sleep 10 --from-id $(/bin/ls -t /var/log/wikidata/rebuildTermSqlIndex.log /var/log/wikidata/rebuildTermSqlIndex.log*[0-9] | /usr/bin/xargs -d "\n" /usr/bin/tac 2> /dev/null | /usr/bin/awk \'/Processed up to page (\d+?)/ { print $5 }\' | head -n1) >> /var/log/wikidata/rebuildTermSqlIndex.log 2>&1',
        user    => $::mediawiki::users::web,
        minute  => 30,
        hour    => '*',
        weekday => '*',
        require => File['/var/log/wikidata'],
    }
}
