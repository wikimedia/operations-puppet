# HP Raid controller
class raid::ssacli {
  require_package('ssacli')

  sudo::user { 'nagios_ssacli':
    user       => 'nagios',
    privileges => [
      'ALL = NOPASSWD: /usr/sbin/ssacli controller all show',
      'ALL = NOPASSWD: /usr/sbin/ssacli controller all show detail',
      'ALL = NOPASSWD: /usr/sbin/ssacli controller slot=[0-9] ld all show',
      'ALL = NOPASSWD: /usr/sbin/ssacli controller slot=[0-9] ld all show detail',
      'ALL = NOPASSWD: /usr/sbin/ssacli controller slot=[0-9] ld * show',
      'ALL = NOPASSWD: /usr/sbin/ssacli controller slot=[0-9] pd all show',
      'ALL = NOPASSWD: /usr/sbin/ssacli controller slot=[0-9] pd all show detail',
      'ALL = NOPASSWD: /usr/sbin/ssacli controller slot=[0-9] pd [0-9]\:[0-9] show',
      'ALL = NOPASSWD: /usr/sbin/ssacli controller slot=[0-9] pd [0-9][EIC]\:[0-9]\:[0-9] show',
      'ALL = NOPASSWD: /usr/sbin/ssacli controller slot=[0-9] pd [0-9][EIC]\:[0-9]\:[0-9][0-9] show',
      'ALL = NOPASSWD: /usr/sbin/ssacli controller slot=[0-9] show status',
      'ALL = NOPASSWD: /usr/sbin/ssacli controller slot=[0-9] show detail',
    ],
  }

  nrpe::monitor_service { 'raid_ssacli':
    description    => 'HP RAID',
    nrpe_command   => '/usr/local/lib/nagios/plugins/check_ssacli',
    timeout        => 90, # can take > 10s on servers with lots of disks
    check_interval => $raid::check_interval,
    retry_interval => $raid::retry_interval,
    event_handler  => "raid_handler!ssacli!${::site}",
    notes_url      => 'https://wikitech.wikimedia.org/wiki/Dc-operations/Hardware_Troubleshooting_Runbook#Hardware_Raid_Information_Gathering',
  }

  file { '/usr/local/lib/nagios/plugins/check_ssacli':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0555',
    source => 'puppet:///modules/raid/dsa-check-hpssacli',
  }

  $get_raid_status_ssacli = '/usr/local/lib/nagios/plugins/get-raid-status-ssacli'
  file { $get_raid_status_ssacli:
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0555',
    source => 'puppet:///modules/raid/get-raid-status-ssacli.sh';
  }
  nrpe::check { 'get_raid_status_ssacli':
    command => "${get_raid_status_ssacli} -c",
  }
}
