# SPDX-License-Identifier: Apache-2.0
# MD RAID controller
class raid::md (
    Enum['present', 'absent'] $cron_ensure = 'present',
) {
  include raid

  # T162013 - reduce raid resync speeds on clustered etcd noes with software RAID
  # in order to mitigate the risk of losing consensus due to I/O latencies
  sysctl::parameters { 'raid_resync_speed':
      ensure => present,
      values => { 'dev.raid.speed_limit_max' => '20000' },
  }
  # Only run on a weekday of our choice, and vary it between servers
  $dow = fqdn_rand(5, 'md_checkarray_dow') + 1
  # Only run within a specific (February compatible) day of month range
  $dom_start = fqdn_rand(28 - 7, 'md_checkarray_dom') + 1
  $dom_end = $dom_start + 7
  # Replace the default mdadm script from upstream with our own
  file { '/etc/cron.d/mdadm':
      ensure  => $cron_ensure,
      content => template('raid/mdadm-cron.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
  }

  nrpe::monitor_service { 'raid_md':
    description    => 'MD RAID',
    nrpe_command   => "${raid::check_raid} md",
    event_handler  => "raid_handler!md!${::site}",
    notes_url      => 'https://wikitech.wikimedia.org/wiki/Dc-operations/Hardware_Troubleshooting_Runbook#Hardware_Raid_Information_Gathering',
    check_interval => 10,
  }

  nrpe::check { 'get_raid_status_md':
    command => 'cat /proc/mdstat',
  }

}
