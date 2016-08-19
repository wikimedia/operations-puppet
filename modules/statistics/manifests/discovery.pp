
class statistics::discovery {
  Class['::statistics'] -> Class['::statistics::discovery']

  $statistics_working_path = $::statistics::working_path
  $dir = "${statistics_working_path}/discovery-stats"
  user { $user:
    ensure => present,
    home => $dir
  }
  $data_dir  = "${dir}/data"
  $scripts_dir  = "${dir}/src"

  $statsd_host = hiera('statsd')
  # TODO graphite hostname should be in hiera
  $graphite_host = 'graphite.eqiad.wmnet'

  # Path in which all crons will log to.
  $log_dir = "${dir}/log"

  $wmde_secrets = hiera('wmde_secrets')

  require_package(
    'php5',
    'php5-cli',
    'git')

  $directories = [
    $dir,
    $scripts_dir,
    $log_dir
  ]

  file { $directories:
    ensure  => 'directory',
    owner   => $user,
    group   => $user,
    mode    => '0644',
    require => User[$user],
  }

  git::clone { 'analytics/discovery-stats':
    ensure    => 'latest',
    branch    => 'production',
    origin    => 'https://gerrit.wikimedia.org/r/analytics/discovery-stats',
    owner     => $user,
    group     => $user,
    require   => File["${dir}/src"],
  }

  logrotate::conf { 'analytics/discovery-stats':
    ensure  => present,
    content => template('statistics/wmde/logrotate.erb'),
    require => File[$log_dir],
  }

  Cron {
    user => $user,
  }

  cron { 'discovery-stats':
    command => "/usr/bin/php ${scripts_dir}/tracking-category-count.php >> ${log_dir}/minutely.log 2>&1",
    hour    => '*',
    require => Git::Clone['wmde/scripts'],
  }

}
