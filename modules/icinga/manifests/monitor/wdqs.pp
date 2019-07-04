# Monitor Wikidata query service
class icinga::monitor::wdqs {

    # raise a warning / critical alert if response time was over 2 minutes / 5 minutes
    # more than 5% of the time during the last minute
    monitoring::graphite_threshold { 'wdqs-response-time-codfw':
        description     => 'Response time of WDQS codfw',
        dashboard_links => ['https://grafana.wikimedia.org/d/000000522/wikidata-query-service-frontend?panelId=13&fullscreen&orgId=1'],
        host            => 'wdqs.svc.codfw.wmnet',
        metric          => 'varnish.codfw.backends.be_wdqs_svc_codfw_wmnet.GET.p99',
        warning         => 120000, # 2 minutes
        critical        => 300000, # 5 minutes
        from            => '10min',
        percentage      => 5,
        contact_group   => 'wdqs-admins',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Wikidata_query_service/Runbook#Timeouts',
    }

    monitoring::graphite_threshold { 'wdqs-response-time-eqiad':
        description     => 'Response time of WDQS eqiad',
        dashboard_links => ['https://grafana.wikimedia.org/d/000000522/wikidata-query-service-frontend?panelId=13&fullscreen&orgId=1'],
        host            => 'wdqs.svc.eqiad.wmnet',
        metric          => 'varnish.eqiad.backends.be_wdqs_svc_eqiad_wmnet.GET.p99',
        warning         => 120000, # 2 minutes
        critical        => 300000, # 5 minutes
        from            => '10min',
        percentage      => 5,
        contact_group   => 'wdqs-admins',
        notes_link      => 'https://wikitech.wikimedia.org/wiki/Wikidata_query_service/Runbook#Timeouts',
    }

}
