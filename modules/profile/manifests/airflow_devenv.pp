# SPDX-License-Identifier: Apache-2.0
class profile::airflow_devenv {
  package { 'airflow-devenv':
    ensure => latest,
  }
}
