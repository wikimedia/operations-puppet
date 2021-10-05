class profile::mediawiki::maintenance::wikidata {
    require profile::mediawiki::common

    # Prune wb_changes entries no longer needed from wikidata
    profile::mediawiki::periodic_job { 'wikibase_repo_prune2':
        command  => '/usr/local/bin/mwscript extensions/Wikibase/repo/maintenance/pruneChanges.php --wiki wikidatawiki --number-of-days=3',
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
