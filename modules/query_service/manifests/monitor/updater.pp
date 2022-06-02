# SPDX-License-Identifier: Apache-2.0
class query_service::monitor::updater (
    String $username,
    String $updater_main_class,
){
    nrpe::monitor_service { 'Query_Service_Updater_process':
        description  => 'Updater process',
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -w 1:1 -u ${username} --ereg-argument-array '^java .* ${updater_main_class}'",
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Wikidata_query_service/Runbook',
    }
}
