# SPDX-License-Identifier: Apache-2.0
# Megaraid controler
class raid::megaraid {
  include raid

  ensure_packages('megacli')

  nrpe::plugin { 'get-raid-status-megacli':
    source => 'puppet:///modules/raid/get-raid-status-megacli.py';
  }

  nrpe::check { 'get_raid_status_megacli':
    command   => '/usr/local/lib/nagios/plugins/get-raid-status-megacli -c',
    sudo_user => 'root',
  }

  nrpe::monitor_service { 'raid_megaraid':
    description    => 'MegaRAID',
    nrpe_command   => "${raid::check_raid} megacli",
    sudo_user      => 'root',
    check_interval => $raid::check_interval,
    retry_interval => $raid::retry_interval,
    event_handler  => "raid_handler!megacli!${::site}",
    notes_url      => 'https://wikitech.wikimedia.org/wiki/MegaCli#Monitoring',
  }

}
