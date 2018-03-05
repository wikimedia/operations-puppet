# == Class: wdqs::monitor::services
#
# Service monitoring for WDQS setup
#
class wdqs::monitor::services(
    $contact_groups,
    $username=$::wdqs::username,
) {

    require_package('python3-requests')
    file { '/usr/lib/nagios/plugins/check_wdqs_categories.py':
        source => 'puppet:///modules/wdqs/nagios/check_wdqs_categories.py',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }


    # categories are updated weekly, this is a low frequency check
    nrpe::monitor_service { 'WDQS_Categories_Lag':
        description    => 'WDQS Categories update lag',
        nrpe_command   => '/usr/lib/nagios/plugins/check_wdqs_categories.py',
        check_interval => 720, # every 6 hours
        retry_interval => 60,  # retry after 1 hour
    }

    nrpe::monitor_service { 'WDQS_Internal_HTTP_endpoint':
        description  => 'WDQS HTTP Port',
        nrpe_command => '/usr/lib/nagios/plugins/check_http -H 127.0.0.1 -p 80 -w 10 -u /readiness-probe',
    }

    nrpe::monitor_service { 'WDQS_Local_Blazegraph_endpoint':
        description  => 'Blazegraph Port',
        nrpe_command => '/usr/lib/nagios/plugins/check_tcp -H 127.0.0.1 -p 9999',
    }

    monitoring::service { 'WDQS_External_HTTP_Endpoint':
        description   => 'WDQS HTTP',
        check_command => 'check_http!query.wikidata.org!/!Welcome',
    }

    monitoring::service { 'WDQS_External_SPARQL_Endpoint':
        description   => 'WDQS SPARQL',
        check_command => 'check_http!query.wikidata.org!/bigdata/namespace/wdq/sparql?query=prefix%20schema:%20%3Chttp://schema.org/%3E%20SELECT%20*%20WHERE%20%7B%3Chttp://www.wikidata.org%3E%20schema:dateModified%20?y%7D&format=json!"xsd:dateTime"',
    }

    nrpe::monitor_service { 'WDQS_Blazegraph_process':
        description  => 'Blazegraph process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -u ${username} --ereg-argument-array '^java .* blazegraph-service-.*war'",
    }

    nrpe::monitor_service { 'WDQS_Updater_process':
        description  => 'Updater process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -w 1:1 -u ${username} --ereg-argument-array '^java .* org.wikidata.query.rdf.tool.Update'",
    }

    monitoring::check_prometheus { 'WDQS_Lag':
        description     => 'High lag',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/wikidata-query-service?orgId=1&panelId=8&fullscreen'],
        query           => "blazegraph_lastupdated{instance='${::hostname}:9193'}",
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        warning         => '1200', # 20 minutes
        critical        => '3600', # 60 minutes
        contact_group   => $contact_groups,
    }
}
