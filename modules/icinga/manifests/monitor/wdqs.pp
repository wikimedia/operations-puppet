# Monitor Wikidata query service
class icinga::monitor::wdqs {

    # raise a warning / critical alert if response time was over 2 minutes / 5 minutes
    monitoring::check_prometheus {
        default:
            dashboard_links => ['https://grafana.wikimedia.org/d/000000522/wikidata-query-service-frontend?panelId=13&fullscreen&orgId=1'],
            query           => 'histogram_quantile(0.99, sum (rate(varnish_backend_requests_seconds_bucket{backend=~".*wdqs.*"}[10m])) by (le))',
            warning         => 120, # 2 minutes
            critical        => 300, # 5 minutes
            contact_group   => 'wdqs-admins',
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Wikidata_query_service/Runbook#Timeouts';
        'wdqs-response-time-codfw':
            description    => 'Response time of WDQS codfw',
            prometheus_url => 'http://prometheus.svc.codfw.wmnet/ops';
        'wdqs-response-time-eqiad':
            description    => 'Response time of WDQS eqiad',
            prometheus_url => 'http://prometheus.svc.eqiad.wmnet/ops';
    }

}
