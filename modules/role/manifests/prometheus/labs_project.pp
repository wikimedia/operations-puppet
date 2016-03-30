# == Class: role::prometheus::labs_project
#
# This class provides a prometheus server to do node (host) monitoring for all
# instances of the labs projects it is running in.
# Instance autodiscovery is accomplished by querying wikitech HTTP API for
# instances list and writing a list of <instance>:9100 'targets' for prometheus
# to pick up. See also prometheus::node_exporter.

class role::prometheus::labs_project {
  include prometheus::server

  $targets_file = '/etc/prometheus/targets/node_project.yml'

  require_package('python3-yaml')
  # XXX create /etc/prometheus/targets

  cron { 'prometheus_labs_project_targets':
    ensure  => present,
    command => "/usr/local/bin/prometheus-labs-targets > ${targets_file}.$$ && mv ${targets_file}.$$ ${targets_file}",
    minute  => '*/10',
    hour    => '*',
    require => Class['prometheus::server'],
  }
}
