# SPDX-License-Identifier: Apache-2.0
# MD RAID controller
class raid::md (
    Enum['present', 'absent'] $timer_ensure = 'present',
) {
  include raid

  # T162013 - reduce raid resync speeds on clustered etcd noes with software RAID
  # in order to mitigate the risk of losing consensus due to I/O latencies
  sysctl::parameters { 'raid_resync_speed':
      ensure => present,
      values => { 'dev.raid.speed_limit_max' => '20000' },
  }

  # Only run on a work day of our choice, and vary it between servers.
  # List the days the timers is allowed to run, and pick on at random.
  $weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']
  $dow = $weekdays[fqdn_rand($weekdays.size(), 'md_checkarray_dow')]

  # Only run within a specific (February compatible) day of month range.
  # These are used in the script called by the timer, as there are no
  # way to make systemd timers (or crontab), run "the second Tuesday of each
  # month".
  $dom_start = fqdn_rand(28 - 7, 'md_checkarray_dom') + 1
  $dom_end = $dom_start + 7

  # Remove the default script from the Debian package.
  # Do not remove this section, as the file will be
  # reintroduced when the Debian updates the package
  # in the future.
  file { '/etc/cron.d/mdadm':
      ensure => absent,
  }

  file { '/usr/local/sbin/mdadm_check_array.sh':
      ensure  => $timer_ensure,
      content => template('raid/mdadm-check-array.erb'),
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
  }

  systemd::timer::job {'mdadm_check_array':
      ensure      => $timer_ensure,
      description => 'Check md raid array',
      user        => 'root',
      command     => '/usr/local/sbin/mdadm_check_array.sh',
      interval    => {'start' => 'OnCalendar', 'interval' => "${dow} *-*-* 05:57:00"}
  }

  nrpe::monitor_service { 'raid_md':
    description    => 'MD RAID',
    nrpe_command   => "${raid::check_raid} md",
    sudo_user      => 'root',
    event_handler  => "raid_handler!md!${::site}",
    notes_url      => 'https://wikitech.wikimedia.org/wiki/Dc-operations/Hardware_Troubleshooting_Runbook#Hardware_Raid_Information_Gathering',
    check_interval => 10,
  }

  nrpe::check { 'get_raid_status_md':
    command => 'cat /proc/mdstat',
  }

}
