class query_service::monitor::gui {
    # TODO: Move to profile
    monitoring::service { 'WDQS_External_HTTP_Endpoint':
        description   => 'WDQS HTTP',
        check_command => 'check_http!query.wikidata.org!/!Welcome',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Wikidata_query_service/Runbook',
    }
}
