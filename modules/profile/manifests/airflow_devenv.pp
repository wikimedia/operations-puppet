# SPDX-License-Identifier: Apache-2.0
class profile::airflow_devenv (
    Optional[String] $version = lookup('profile::airflow_devenv::version', { 'default_value' => '0.0.2' }),
) {
  package { 'airflow-devenv':
    ensure => $version,
  }
}
