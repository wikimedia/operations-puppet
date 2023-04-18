# SPDX-License-Identifier: Apache-2.0
# LSI SAS3008 HBA (Host Bus Adapter) management - e.g. Dell PowerEdge HBA330 mini
# These devices provide SAS expansion features, but no hardware RAID capability.
class raid::perccli_hba {
    include raid

    ensure_packages('perccli')

    # TODO - We wish to measure the health of the controller and the drives
    # nrpe::plugin { 'get-hba-status-perccli':
    #     source => 'puppet:///modules/raid/get-hba-status-perccli.py';
    # }

    # nrpe::check { 'get_hba_status_perccli':
    #     command   => '/usr/local/lib/nagios/plugins/get-hba-status-perccli',
    #     sudo_user => 'root',
    # }

    # nrpe::monitor_service { 'perc_hba':
    #     description    => 'Dell PowerEdge Host Bus Adapter',
    #     nrpe_command   => '/usr/local/lib/nagios/plugins/get-hba-status-perccli',
    #     sudo_user      => 'root',
    #     check_interval => $raid::check_interval,
    #     retry_interval => $raid::retry_interval,
    #     event_handler  => "raid_handler!perccli_hba!${::site}",
    #     notes_url      => 'https://wikitech.wikimedia.org/wiki/PERCCli#Monitoring',
    # }
}
