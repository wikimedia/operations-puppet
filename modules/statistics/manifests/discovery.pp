
class statistics::discovery {
  Class['::statistics'] -> Class['::statistics::discovery']

  $statistics_working_path = $::statistics::working_path
  $dir = "${statistics_working_path}/discovery-stats"
  $user = 'discovery-stats'

  user { $user:
    ensure     => present,
    home       => $dir,
    shell      => '/bin/bash',
    managehome => false,
    home       => $dir,
    system     => true,
  }

  # Path in which all crons will log to
  $log_dir = "${dir}/log"

  require_package(
    'php5',
    'php5-cli',
    'git')

  $directories = [
    $dir,
    $log_dir
  ]

  file { $directories:
    ensure  => 'directory',
    owner   => $user,
    group   => $user,
    mode    => '0755',
  }

  git::clone { 'analytics/discovery-stats':
    ensure    => 'latest',
    branch    => 'production',
    directory => $dir,
    origin    => 'https://gerrit.wikimedia.org/r/analytics/discovery-stats',
    owner     => $user,
    group     => $user,
    require   => File[$dir],
  }

  logrotate::conf { 'analytics/discovery-stats':
    ensure  => present,
    content => template('statistics/discovery-stats.logrotate.erb'),
    require => File[$log_dir],
  }

  cron { 'discovery-stats':
    command => "/usr/bin/php ${dir}/tracking-category-count.php >> ${log_dir}/tracking-category-count.log 2>&1",
    hour    => '*',
    require => Git::Clone['analytics/discovery-stats'],
    user    => $user,
  }

}
