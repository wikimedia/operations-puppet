# SPDX-License-Identifier: Apache-2.0
# HP Raid controller
class raid::hpsa::hpssacli {
  assert_private()

  nrpe::plugin { 'check_hpssacli':
    source => 'puppet:///modules/raid/dsa-check-hpssacli',
  }

  sudo::user { 'nagios_hpssacli':
    user       => 'nagios',
    privileges => [
      'ALL = NOPASSWD: /usr/sbin/hpssacli controller all show',
      'ALL = NOPASSWD: /usr/sbin/hpssacli controller all show detail',
      'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0-9] ld all show',
      'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0-9] ld all show detail',
      'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0-9] ld * show',
      'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0-9] pd all show',
      'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0-9] pd all show detail',
      'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0-9] pd [0-9]\:[0-9] show',
      'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0-9] pd [0-9][EIC]\:[0-9]\:[0-9] show',
      'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0-9] pd [0-9][EIC]\:[0-9]\:[0-9][0-9] show',
      'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0-9] show status',
      'ALL = NOPASSWD: /usr/sbin/hpssacli controller slot=[0-9] show detail',
      'ALL = NOPASSWD: /usr/sbin/hpacucli controller all show',
      'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0-9] ld all show',
      'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0-9] ld * show',
      'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0-9] pd all show',
      'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0-9] pd [0-9]\:[0-9] show',
      'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0-9] pd [0-9][EIC]\:[0-9]\:[0-9] show',
      'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0-9] pd [0-9][EIC]\:[0-9]\:[0-9][0-9] show',
      'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0-9] show status',
      'ALL = NOPASSWD: /usr/sbin/hpacucli controller slot=[0-9] show detail',
    ],
  }

  nrpe::monitor_service { 'raid_hpssacli':
    description    => 'HP RAID',
    nrpe_command   => '/usr/local/lib/nagios/plugins/check_hpssacli',
    timeout        => 90, # can take > 10s on servers with lots of disks
    check_interval => $raid::check_interval,
    retry_interval => $raid::retry_interval,
    event_handler  => "raid_handler!hpssacli!${::site}",
    notes_url      => 'https://wikitech.wikimedia.org/wiki/Dc-operations/Hardware_Troubleshooting_Runbook#Hardware_Raid_Information_Gathering',
  }

  nrpe::plugin { 'get-raid-status-hpssacli':
    source => 'puppet:///modules/raid/get-raid-status-hpssacli.sh';
  }

  nrpe::check { 'get_raid_status_hpssacli':
    command => '/usr/local/lib/nagios/plugins/get-raid-status-hpssacli -c',
  }
}
