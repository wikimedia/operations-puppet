class wdqs::monitor::updater (
    String $username,
){
    nrpe::monitor_service { 'WDQS_Updater_process':
        description  => 'Updater process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -w 1:1 -u ${username} --ereg-argument-array '^java .* org.wikidata.query.rdf.tool.Update'",
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Wikidata_query_service/Runbook',
    }
}
