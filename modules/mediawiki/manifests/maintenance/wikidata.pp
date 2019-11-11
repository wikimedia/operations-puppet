class mediawiki::maintenance::wikidata( $ensure = present, $ensure_testwiki = present ) {
    require ::mediawiki::users

    $dispatch_log_file = '/var/log/wikidata/dispatchChanges-wikidatawiki.log'
    $test_dispatch_log_file = '/var/log/wikidata/dispatchChanges-testwikidatawiki.log'

    # Starts a dispatcher instance every 3 minutes:
    # This handles inserting jobs into client job queue, which then processes the changes.
    # They will run for a limited time, so we can only have runTimeInMinutes/3m concurrent instances.
    # The settings for dispatchChanges.php can be found in mediawiki-config.
    # Docs for the settings can be found in https://phabricator.wikimedia.org/diffusion/EWBA/browse/master/docs/options.wiki by searching for "dispatchChanges.php"
    # All settings can still be overridden at run time if required.

    cron { 'wikibase-dispatch-changes4':
        ensure  => $ensure,
        command => "echo \"\$\$: Starting dispatcher\" >> ${dispatch_log_file}; /usr/local/bin/mwscript extensions/Wikibase/repo/maintenance/dispatchChanges.php --wiki wikidatawiki >> ${dispatch_log_file} 2>&1; echo \"\$\$: Dispatcher exited with $?\" >> ${dispatch_log_file}",
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

    $log_ownership_user = $::mediawiki::users::web
    $log_ownership_group = $::mediawiki::users::web
    logrotate::conf { 'wikidata':
        ensure  => $ensure,
        content => template('mediawiki/maintenance/logrotate.d_wikidata.erb'),
    }

    # Migrating item terms for the new term store
    cron { 'wikidata-rebuildItemTerms':
        ensure  => $ensure,
        command => '/usr/bin/timeout 3500s /usr/local/bin/mwscript extensions/Wikibase/repo/maintenance/rebuildItemTerms.php --wiki wikidatawiki --sleep 2 --from-id $(/bin/sed -n \'/Rebuilding Q[[:digit:]]\+ till Q\([[:digit:]]\+\)/ { s//\1/; p; }\' /var/log/wikidata/wikidata-rebuildItemTerms.log* | /usr/bin/sort -rn | /usr/bin/head -1) >> /var/log/wikidata/wikidata-rebuildItemTerms.log 2>&1',
        user    => $::mediawiki::users::web,
        minute  => 30,
        hour    => '*',
        weekday => '*',
        require => File['/var/log/wikidata'],
    }

}
