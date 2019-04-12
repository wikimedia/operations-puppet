# MD RAID controller
class raid::md {
  include raid

  nrpe::monitor_service { 'raid_md':
    description   => 'MD RAID',
    nrpe_command  => "${raid::check_raid} md",
    event_handler => "raid_handler!md!${::site}",
  }

  nrpe::check { 'get_raid_status_md':
    command => 'cat /proc/mdstat',
  }

}
