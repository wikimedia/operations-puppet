# == Class: role::prometheus::labs_project
#
# This class provides a prometheus server to do node (host) monitoring for all
# instances of the labs projects it is running in.
# Instance autodiscovery is accomplished by querying wikitech HTTP API for
# instances list and writing a list of <instance>:9100 'targets' for prometheus
# to pick up. See also prometheus::node_exporter.

class role::prometheus::labs_project {
  prometheus::server { 'labs':
    listen_address => '127.0.0.1:9901'
  }

  prometheus::web { 'labs':
    proxy_pass => 'http://127.0.0.1:9901/labs',
  }

  $targets_file = '/srv/prometheus/labs/targets/node_project.yml'

  include ::prometheus::wmcs_scripts

  cron { 'prometheus_labs_project_targets':
    ensure  => present,
    command => "/usr/local/bin/prometheus-labs-targets > ${targets_file}.$$ && mv ${targets_file}.$$ ${targets_file}",
    minute  => '*/10',
    hour    => '*',
    user    => 'prometheus',
  }
}
