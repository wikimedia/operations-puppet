class wdqs::monitor::gui {
    monitoring::service { 'WDQS_External_HTTP_Endpoint':
        description   => 'WDQS HTTP',
        check_command => 'check_http!query.wikidata.org!/!Welcome',
    }
}