# Monitor exteral blazegraph settings
class wdqs::monitor::blazegraph (
    String $username,
    String $contact_groups,
    Integer[0] $lag_warning,
    Integer[0] $lag_critical,
) {
    require_package('python3-requests')
    file { '/usr/lib/nagios/plugins/check_wdqs_categories.py':
        source => 'puppet:///modules/wdqs/nagios/check_wdqs_categories.py',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    # categories are updated weekly, this is a low frequency check
    nrpe::monitor_service { 'WDQS_Categories_Ping':
        description    => 'WDQS Categories endpoint',
        nrpe_command   => '/usr/lib/nagios/plugins/check_wdqs_categories.py --ping',
        check_interval => 720, # every 6 hours
        retry_interval => 60,  # retry after 1 hour
    }

    nrpe::monitor_service { 'WDQS_Categories_Lag':
        description    => 'WDQS Categories update lag',
        nrpe_command   => '/usr/lib/nagios/plugins/check_wdqs_categories.py --lag',
        check_interval => 720, # every 6 hours
        retry_interval => 60,  # retry after 1 hour
    }

    nrpe::monitor_service { 'WDQS_Internal_HTTP_endpoint':
        description  => 'WDQS HTTP Port',
        nrpe_command => '/usr/lib/nagios/plugins/check_http -H 127.0.0.1 -p 80 -w 10 -u /readiness-probe',
    }

    monitoring::service { 'WDQS_External_SPARQL_Endpoint':
        description   => 'WDQS SPARQL',
        check_command => 'check_http!query.wikidata.org!/bigdata/namespace/wdq/sparql?query=prefix%20schema:%20%3Chttp://schema.org/%3E%20SELECT%20*%20WHERE%20%7B%3Chttp://www.wikidata.org%3E%20schema:dateModified%20?y%7D&format=json!"xsd:dateTime"',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Wikidata_query_service/Runbook',
    }

    monitoring::check_prometheus { 'WDQS_Lag':
        description     => 'High lag',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/wikidata-query-service?orgId=1&panelId=8&fullscreen'],
        query           => "scalar(time() - blazegraph_lastupdated{instance=\"${::hostname}:9193\"})",
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        warning         => $lag_warning,
        critical        => $lag_critical,
        contact_group   => $contact_groups,
    }

}
