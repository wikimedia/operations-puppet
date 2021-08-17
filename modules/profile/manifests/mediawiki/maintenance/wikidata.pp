class profile::mediawiki::maintenance::wikidata {
    require profile::mediawiki::common

    # Starts a dispatcher instance every 3 minutes:
    # This handles inserting jobs into client job queue, which then processes the changes.
    # They will run for a limited time, so we can only have runTimeInMinutes/3m concurrent instances.
    # The settings for dispatchChanges.php can be found in mediawiki-config.
    # Docs for the settings can be found in https://doc.wikimedia.org/Wikibase/master/php/md_docs_topics_options.html by searching for "dispatchChanges.php"
    # All settings can still be overridden at run time if required.
    profile::mediawiki::periodic_job { 'wikibase-dispatch-changes1':
        command  => '/usr/local/bin/mwscript extensions/Wikibase/repo/maintenance/dispatchChanges.php --wiki wikidatawiki',
        interval => '*-*-* *:0/3:00'
    }
    profile::mediawiki::periodic_job { 'wikibase-dispatch-changes2':
        command  => '/usr/local/bin/mwscript extensions/Wikibase/repo/maintenance/dispatchChanges.php --wiki wikidatawiki',
        interval => '*-*-* *:01/3:00'
    }
    profile::mediawiki::periodic_job { 'wikibase-dispatch-changes3':
        command  => '/usr/local/bin/mwscript extensions/Wikibase/repo/maintenance/dispatchChanges.php --wiki wikidatawiki',
        interval => '*-*-* *:02/3:00'
    }

    profile::mediawiki::periodic_job { 'wikibase-dispatch-changes-test':
        command  => '/usr/local/bin/mwscript extensions/Wikibase/repo/maintenance/dispatchChanges.php --wiki testwikidatawiki',
        interval => '*-*-* *:0/15:00'
    }

    # Prune wb_changes entries no longer needed from (test)wikidata
    profile::mediawiki::periodic_job { 'wikibase_repo_prune2':
        command  => '/usr/local/bin/mwscript extensions/Wikibase/repo/maintenance/pruneChanges.php --wiki wikidatawiki --number-of-days=3',
        interval => '*:00,15,30,45',
    }

    profile::mediawiki::periodic_job { 'wikibase_repo_prune_test':
        command  => '/usr/local/bin/mwscript extensions/Wikibase/repo/maintenance/pruneChanges.php --wiki testwikidatawiki --number-of-days=3',
        interval => '*:00,15,30,45',
    }

    # Update the cached query service maxlag value every minute
    # We don't need to ensure present/absent as the wrapper will ensure nothing
    # is run unless we're in the master dc
    # Logs are saved to /var/log/mediawiki/mediawiki_job_wikidata-updateQueryServiceLag/syslog.log and properly rotated.
    profile::mediawiki::periodic_job { 'wikidata-updateQueryServiceLag':
        command  => '/usr/local/bin/mwscript extensions/Wikidata.org/maintenance/updateQueryServiceLag.php --wiki wikidatawiki --cluster wdqs --prometheus prometheus.svc.eqiad.wmnet --prometheus prometheus.svc.codfw.wmnet',
        interval => '*-*-* *:*:00'
    }
}
