# SPDX-License-Identifier: Apache-2.0
# Dell PowerEdge RAID Controler
class raid::perccli {
    include raid

    ensure_packages('perccli')
    $get_raid_status_perccli = '/usr/local/lib/nagios/plugins/get-raid-status-perccli'

    file { $get_raid_status_perccli:
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/raid/get-raid-status-perccli.py';
    }

    sudo::user { 'nagios_perc_raid':
        user       => 'nagios',
        privileges => ["ALL = NOPASSWD: ${get_raid_status_perccli}"],
    }

    nrpe::check { 'get_raid_status_perccli':
        command => "/usr/bin/sudo ${get_raid_status_perccli}",
    }

    nrpe::monitor_service { 'raid_perc_raid':
        description    => 'Dell PowerEdge RAID Controller',
        nrpe_command   => "${raid::check_raid} perccli",
        check_interval => $raid::check_interval,
        retry_interval => $raid::retry_interval,
        event_handler  => "raid_handler!perccli!${::site}",
        notes_url      => 'https://wikitech.wikimedia.org/wiki/PERCCli#Monitoring',
    }
}
