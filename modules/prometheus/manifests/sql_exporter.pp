# SPDX-License-Identifier: Apache-2.0
# == Define: prometheus::sql_exporter
#
# This Prometheus exporter extracts various metrics from PostgreSQL, MySQL, and MSSQL databases.
# The metrics are configurable via a YAML file
#
# = Parameters
# [**job_name**]
#   The unique name of the job e.g. some_service_metrics
#
# [**db_connection**]
#   The database connection string e.g. mysql://user:Password123!@tcp(127.0.0.1:3306)/database
#   A valid connection string for the given database should be fine.
#
# [**metrics**]
#   This is a key-value pair of the metrics to collect. The key is the name of the metric
#   and the value is the query e.g.
#     metrics       => {
#       'active_users'   => 'select count(*) from users where last_login > some_date;'
#     }
class prometheus::sql_exporter (
  String $job_name,
  String $db_connection,
  Wmflib::Ensure $ensure = 'present',
  Hash[String, String] $metrics = {},
) {
  ensure_packages(['prometheus-sql-exporter'])

  $config = {
    jobs => [
      {
          name => $job_name,
          interval => '5m',
          connections => [ $db_connection ],
          queries => $metrics.map | String $name, String $query | {
              {
                name             => $name,
                values           => ['count'],
                query            => $query,
                allows_zero_rows => true,
              }
          },
      },
    ],
  }

  file { '/etc/prometheus-sql-exporter.yml':
    ensure    => $ensure,
    require   => Package['prometheus-sql-exporter'],
    owner     => 'postgres',
    group     => 'postgres',
    mode      => '0400',
    content   => to_yaml($config),
    notify    => Exec['exporter-restart'],
    show_diff => false,
  }

  exec { 'exporter-restart':
      command     => '/usr/bin/systemctl restart prometheus-sql-exporter',
      refreshonly => true,
  }

  profile::auto_restarts::service { 'prometheus-sql-exporter': }
}
