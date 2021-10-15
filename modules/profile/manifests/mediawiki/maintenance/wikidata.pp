class profile::mediawiki::maintenance::wikidata {
    require profile::mediawiki::common

    # Update the cached query service maxlag value every minute
    # We don't need to ensure present/absent as the wrapper will ensure nothing
    # is run unless we're in the master dc
    # Logs are saved to /var/log/mediawiki/mediawiki_job_wikidata-updateQueryServiceLag/syslog.log and properly rotated.
    profile::mediawiki::periodic_job { 'wikidata-updateQueryServiceLag':
        command  => '/usr/local/bin/mwscript extensions/Wikidata.org/maintenance/updateQueryServiceLag.php --wiki wikidatawiki --cluster wdqs --prometheus prometheus.svc.eqiad.wmnet --prometheus prometheus.svc.codfw.wmnet',
        interval => '*-*-* *:*:00'
    }
}
