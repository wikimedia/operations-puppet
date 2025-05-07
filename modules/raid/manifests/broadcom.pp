# SPDX-License-Identifier: Apache-2.0
# Dell PowerEdge RAID Controller and Supermicro Broadcom Controller
class raid::broadcom {
    include raid

    if $facts['dmi']['board']['manufacturer'] == 'Supermicro' {
        ensure_packages('storcli')
    } else {
        ensure_packages('perccli')
    }

    nrpe::plugin { 'get-raid-status-broadcom':
        source => 'puppet:///modules/raid/get-raid-status-broadcom.py';
    }

    nrpe::check { 'get_raid_status_broadcom':
        command   => '/usr/local/lib/nagios/plugins/get-raid-status-broadcom',
        sudo_user => 'root',
    }

    nrpe::monitor_service { 'raid_broadcom_raid':
        description    => 'Dell PowerEdge RAID / Supermicro Broadcom Controller',
        nrpe_command   => '/usr/local/lib/nagios/plugins/get-raid-status-broadcom',
        sudo_user      => 'root',
        check_interval => $raid::check_interval,
        retry_interval => $raid::retry_interval,
        event_handler  => "raid_handler!broadcom!${::site}",
        notes_url      => 'https://wikitech.wikimedia.org/wiki/PERCCli#Monitoring',
    }
}
