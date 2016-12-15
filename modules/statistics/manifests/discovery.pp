
class statistics::discovery {
  Class['::statistics'] -> Class['::statistics::discovery']

  include ::passwords::mysql::research

  $statistics_working_path = $::statistics::working_path
  $dir = "${statistics_working_path}/discovery-stats"
  $user = 'discovery-stats'

  group { $user:
    ensure => present,
  }

  user { $user:
    ensure     => present,
    home       => $dir,
    shell      => '/bin/bash',
    managehome => false,
    system     => true,
  }

  ::mysql::config::client { 'discovery-stats':
    user    => $::passwords::mysql::research::user,
    pass    => $::passwords::mysql::research::pass,
    group   => $user,
    mode    => '0440',
    require => User[$user],
  }

  # Path in which all crons will log to
  $log_dir = "${dir}/log"

  $scripts_dir = "${dir}/scripts"

  require_package(
    'php5',
    'php5-cli',
  )

  $directories = [
    $dir,
    $log_dir,
  ]

  file { $directories:
    ensure => 'directory',
    owner  => $user,
    group  => $user,
    mode   => '0755',
  }

  git::clone { 'analytics/discovery-stats':
    ensure    => 'latest',
    branch    => 'production',
    directory => $scripts_dir,
    origin    => 'https://gerrit.wikimedia.org/r/analytics/discovery-stats',
    owner     => $user,
    group     => $user,
    require   => File[$dir],
  }

  logrotate::conf { 'analytics-discovery-stats':
    ensure  => present,
    content => template('statistics/discovery-stats.logrotate.erb'),
    require => File[$log_dir],
  }

  cron { 'discovery-stats':
    command => "${scripts_dir}/bin/hourly.sh >> ${log_dir}/hourly.log 2>&1",
    minute  => '14',
    require => Git::Clone['analytics/discovery-stats'],
    user    => $user,
  }

  cron { 'discovery-stats-daily':
    command => "${scripts_dir}/bin/daily.sh >> ${log_dir}/daily.log 2>&1",
    hour    => '3',
    minute  => '14',
    require => Git::Clone['analytics/discovery-stats'],
    user    => $user,
  }
}
