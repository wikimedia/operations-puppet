# Megaraid controler
class raid::megaraid {
  include raid

  require_package('megacli')
  $get_raid_status_megacli = '/usr/local/lib/nagios/plugins/get-raid-status-megacli'

  file { $get_raid_status_megacli:
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0555',
    source => 'puppet:///modules/raid/get-raid-status-megacli.py';
  }

  sudo::user { 'nagios_megaraid':
    user       => 'nagios',
    privileges => ["ALL = NOPASSWD: ${get_raid_status_megacli}"],
  }

  nrpe::check { 'get_raid_status_megacli':
    command => "/usr/bin/sudo ${get_raid_status_megacli} -c",
  }

  nrpe::monitor_service { 'raid_megaraid':
    description    => 'MegaRAID',
    nrpe_command   => "${raid::check_raid} megacli",
    check_interval => $raid::check_interval,
    retry_interval => $raid::retry_interval,
    event_handler  => "raid_handler!megacli!${::site}",
  }

}
