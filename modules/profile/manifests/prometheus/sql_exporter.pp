# SPDX-License-Identifier: Apache-2.0
# define = profile::prometheus::sql_exporter
#
# This Prometheus exporter extracts various metrics from PostgreSQL, MySQL, and MSSQL databases.
# The metrics are configurable via a YAML file

define profile::prometheus::sql_exporter (
  String $job_name,
  String $db_connection,
  Wmflib::Ensure $ensure,
  Hash[String, String] $metrics,
){

  prometheus::sql_exporter { $job_name:
      ensure        => $ensure,
      job_name      => $job_name,
      db_connection => $db_connection,
      metrics       => $metrics,
  }
}
