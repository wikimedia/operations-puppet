class profile::mediawiki::maintenance::wikidata {
    require profile::mediawiki::common

    # Resubmit changes in wb_changes that are older than 6 hours
    profile::mediawiki::periodic_job { 'wikidata_resubmit_changes_for_dispatch':
        command  => '/usr/local/bin/mwscript extensions/Wikibase/repo/maintenance/ResubmitChanges.php --wiki wikidatawiki --minimum-age 21600',
        interval => '*-*-* *:39:00',
    }

    # Update the cached query service maxlag value every minute
    # We don't need to ensure present/absent as the wrapper will ensure nothing
    # is run unless we're in the master dc
    # Logs are saved to /var/log/mediawiki/mediawiki_job_wikidata-updateQueryServiceLag/syslog.log and properly rotated.
    # CODFW temp removed because of https://phabricator.wikimedia.org/T302330
    profile::mediawiki::periodic_job { 'wikidata-updateQueryServiceLag':
        command  => '/usr/local/bin/mwscript extensions/Wikidata.org/maintenance/updateQueryServiceLag.php --wiki wikidatawiki --cluster wdqs --prometheus prometheus.svc.codfw.wmnet',
        interval => '*-*-* *:*:00'
    }
}
