class profile::mediawiki::maintenance::wikidata() {
    require profile::mediawiki::common
    require profile::lvs::configuration
    # Resubmit changes in wb_changes that are older than 6 hours
    profile::mediawiki::periodic_job { 'wikidata_resubmit_changes_for_dispatch':
        command  => '/usr/local/bin/mwscript extensions/Wikibase/repo/maintenance/ResubmitChanges.php --wiki wikidatawiki --minimum-age 21600',
        interval => '*-*-* *:39:00',
    }

    if $::realm != 'labs' {
        # Update the cached query service maxlag value every minute
        # We don't need to ensure present/absent as the wrapper will ensure nothing
        # is run unless we're in the master dc
        # Logs are saved to /var/log/mediawiki/mediawiki_job_wikidata-updateQueryServiceLag/syslog.log and properly rotated.
        # When calculating maxlag, we want to only query WDQS servers that are currently pooled. See T238751
        $service_name = 'wdqs'
        $svc = wmflib::service::fetch(true)[$service_name]
        $svc_lbl = "${service_name}_${svc['port']}"
        # Needed to find the LVS servers we need to check.
        $my_lvs_class = $svc['lvs']['class']
        # Select the virtual LVS instrumentation hostnames for our class at the two core sites:
        $lb = [
            wmflib::service::get_i13n_for_lvs_class($my_lvs_class, 'eqiad'),
            wmflib::service::get_i13n_for_lvs_class($my_lvs_class, 'codfw')
        ].map |$host| { "--lb ${host}:9090" }.join(' ')

        # Set this value relatively low to account for wdqs@codfw which is receiving a lot less traffic than eqiad (see T360993#9669374)
        $pooled_server_min_query_rate = 0.2
        $additional_args = "--lb-pool ${svc_lbl} ${lb} --pooled-server-min-query-rate ${pooled_server_min_query_rate}"
        profile::mediawiki::periodic_job { 'wikidata-updateQueryServiceLag':
            command  => "/usr/local/bin/mwscript extensions/Wikidata.org/maintenance/updateQueryServiceLag.php --wiki wikidatawiki --cluster wdqs --prometheus prometheus.svc.eqiad.wmnet ${additional_args}",
            interval => '*-*-* *:*:00'
        }
    }
}
