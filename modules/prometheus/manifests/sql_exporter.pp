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
#   The database connection string e.g. mysql://user:Password123!@tcp(127.0.0.1)/database
#   A valid connection string for the given database should be fine.
#
# [**metrics**]
#   This is a key-value pair of the metrics to collect. The key is the description of the metric
#   and the value is map with the columns (provided as an array) to be used as the metric
#   and the query provided as a string e.g.
#   metrics       => {
#    'metric_1'   => {
#         'name'  => 'my_metric',
#         'columns' => ['count'],
#         'query'  => 'select count(*) AS count where some_column=value_1',
#     },
#     'metric_2' => {
#         'name'  => 'my_metric',
#         'columns' => ['count'],
#         'labels'  => ['label_1', 'label_2'],
#         'query'   => 'select count(*) AS count where some_column=value_2',
#     }
#   }
#
# [**scrape_interval**]
#   The time between each job runs. Default to five minutes.
#
class prometheus::sql_exporter (
  String $job_name,
  String $db_connection,
  Hash[String, Hash[String, Variant[String, Array]]] $metrics,
  String $scrape_interval = '5m',
  Wmflib::Ensure $ensure = 'present',
) {
  ensure_packages(['prometheus-sql-exporter'])

  $config = {
    jobs => [
      {
          name => $job_name,
          interval => $scrape_interval,
          connections => [ $db_connection ],
          queries => $metrics.map | String $name, Hash $metric | {
            {
                name             => $metric['name'],
                values           => assert_type(Array, $metric['columns']),
                labels           => assert_type(Array, $metric['labels']),
                query            => assert_type(String, $metric['query']),
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
