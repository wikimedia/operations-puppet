# == Class: wdqs::monitor::services
#
# Service monitoring for WDQS setup
#
class wdqs::monitor::services(
    $username=$::wdqs::username
) {

    nrpe::monitor_service { 'WDQS Internal HTTP endpoint':
        description  => 'WDQS HTTP Port',
        nrpe_command => '/usr/lib/nagios/plugins/check_tcp -H 127.0.0.1 -p 80',
    }

    nrpe::monitor_service { 'WDQS Local Blazegraph endpoint':
        description  => 'Blazegraph Port',
        nrpe_command => '/usr/lib/nagios/plugins/check_tcp -H 127.0.0.1 -p 9999',
    }

    monitoring::service { 'WDQS External HTTP Endpoint':
        description   => 'WDQS HTTP',
        check_command => 'check_http!query.wikidata.org!/!Welcome',
    }

    monitoring::service { 'WDQS External SPARQL Endpoint':
        description   => 'WDQS SPARQL',
        check_command => 'check_http!query.wikidata.org!/bigdata/namespace/wdq/sparql?query=prefix%20schema:%20%3Chttp://schema.org/%3E%20SELECT%20*%20WHERE%20%7B%3Chttp://www.wikidata.org%3E%20schema:dateModified%20?y%7D&format=json!"xsd:dateTime"',
    }

    nrpe::monitor_service { 'WDQS Blazegraph process':
        description  => 'Blazegraph process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -u ${username} --ereg-argument-array '^java .* blazegraph-service-.*-dist.war'",
    }

    nrpe::monitor_service { 'WDQS Updater process':
        description  => 'Updater process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -w 1:1 -u ${username} --ereg-argument-array '^java .* org.wikidata.query.rdf.tool.Update'",
    }
}
