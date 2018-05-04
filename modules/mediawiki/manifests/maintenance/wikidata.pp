class mediawiki::maintenance::wikidata( $ensure = present, $ensure_testwiki = present ) {
    require ::mediawiki::users

    # Starts a dispatcher instance every 3 minutes
    # They will run for a maximum of about 10 minutes, so we can only have 4 concurrent instances.
    # This handles inserting jobs into client job queue, which then process the changes
    # This will process up to --batch-size * (60 / --dispatch-interval) changes per minute,
    # to a single wiki (only counting changes that affect the wiki).
    $dispatch_log_file = '/var/log/wikidata/dispatchChanges-wikidatawiki.log'
    $test_dispatch_log_file = '/var/log/wikidata/dispatchChanges-testwikidatawiki.log'

    cron { 'wikibase-dispatch-changes4':
        ensure  => $ensure,
        command => "echo \"\$\$: Starting dispatcher\" >> ${dispatch_log_file}; PHP='hhvm -vEval.Jit=1' /usr/local/bin/mwscript extensions/Wikibase/repo/maintenance/dispatchChanges.php --wiki wikidatawiki >> ${dispatch_log_file} 2>&1; echo \"\$\$: Dispatcher exited with $?\" >> ${dispatch_log_file}",
        user    => $::mediawiki::users::web,
        minute  => '*/3',
        require => File['/var/log/wikidata'],
    }

    cron { 'wikibase-dispatch-changes-test':
        ensure  => $ensure_testwiki,
        command => "echo \"\$\$: Starting dispatcher\" >> ${test_dispatch_log_file}; /usr/local/bin/mwscript extensions/Wikibase/repo/maintenance/dispatchChanges.php --wiki testwikidatawiki >> ${test_dispatch_log_file} 2>&1; echo \"\$\$: Dispatcher exited with $?\" >> ${test_dispatch_log_file}",
        user    => $::mediawiki::users::web,
        minute  => '*/15',
        require => File['/var/log/wikidata'],
    }

    # Prune wb_changes entries no longer needed from (test)wikidata
    cron { 'wikibase-repo-prune2':
        ensure  => $ensure,
        command => '/usr/local/bin/mwscript extensions/Wikibase/repo/maintenance/pruneChanges.php --wiki wikidatawiki --number-of-days=3 >> /var/log/wikidata/prune2.log 2>&1',
        user    => $::mediawiki::users::web,
        minute  => [0,15,30,45],
        require => File['/var/log/wikidata'],
    }

    cron { 'wikibase-repo-prune-test':
        ensure  => $ensure_testwiki,
        command => '/usr/local/bin/mwscript extensions/Wikibase/repo/maintenance/pruneChanges.php --wiki testwikidatawiki --number-of-days=3 >> /var/log/wikidata/prune-testwikidata.log 2>&1',
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
        ensure => $ensure,
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

    # clear term_search_key field in wb_terms table
    cron { 'wikidata-clearTermSqlIndexSearchFields':
        ensure  => $ensure,
        command => '/usr/bin/timeout 3500s /usr/local/bin/mwscript extensions/Wikibase/repo/maintenance/clearTermSqlIndexSearchFields.php --wiki wikidatawiki --sleep 3 --skip-term-weight --from-id $(/bin/sed -n \'/Cleared up to row \([[:digit:]]\+\)/ { s//\1/; p; }\' /var/log/wikidata/clearTermSqlIndexSearchFields.log* | /usr/bin/sort -rn | /usr/bin/head -1) >> /var/log/wikidata/clearTermSqlIndexSearchFields.log 2>&1',
        user    => $::mediawiki::users::web,
        minute  => 30,
        hour    => '*',
        weekday => '*',
        require => File['/var/log/wikidata'],
    }

}
