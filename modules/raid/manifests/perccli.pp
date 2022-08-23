# SPDX-License-Identifier: Apache-2.0
# Dell PowerEdge RAID Controler
class raid::perccli {
    include raid

    ensure_packages('perccli')

    nrpe::plugin { 'get-raid-status-perccli':
        source => 'puppet:///modules/raid/get-raid-status-perccli.py';
    }

    sudo::user { 'nagios_perc_raid':
        ensure => absent,
    }

    nrpe::check { 'get_raid_status_perccli':
        command   => '/usr/local/lib/nagios/plugins/get-raid-status-perccli',
        sudo_user => 'root',
    }

    nrpe::monitor_service { 'raid_perc_raid':
        description    => 'Dell PowerEdge RAID Controller',
        nrpe_command   => "${raid::check_raid} perccli",
        sudo_user      => 'root',
        check_interval => $raid::check_interval,
        retry_interval => $raid::retry_interval,
        event_handler  => "raid_handler!perccli!${::site}",
        notes_url      => 'https://wikitech.wikimedia.org/wiki/PERCCli#Monitoring',
    }
}
