# MPT RAID controller
class raid::mpt {
  include raid
  package { 'mpt-status':
    ensure => present,
  }

  file { '/etc/default/mpt-statusd':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    content => "RUN_DAEMON=no\n",
    before  => Package['mpt-status'],
  }

  nrpe::monitor_service { 'raid_mpt':
    description    => 'MPT RAID',
    nrpe_command   => "${raid::check_raid} mpt",
    check_interval => $raid::check_interval,
    retry_interval => $raid::retry_interval,
    event_handler  => "raid_handler!mpt!${::site}",
    notes_url      => 'https://wikitech.wikimedia.org/wiki/MegaCli#Monitoring',
  }

  nrpe::check { 'get_raid_status_mpt':
    command => "${raid::check_raid} mpt",
  }
}
