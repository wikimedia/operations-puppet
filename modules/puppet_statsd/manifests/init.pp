# == Class: puppet_statsd
#
# This module configures a Puppet reporter that sends timing information
# on Puppet runs to StatsD.
#
# === Parameters
#
# [*statsd_host*]
#  StatsD host to send metrics to.
#
# [*statsd_port*]
#  Port on which StatsD host is listening (default: 8125).
#
# [*metric_format*]
#  ERB Template string for metric names; the variables 'hostname' and
#  'metric' will be set in template scope to the local hostname and the
#  metric name, respectively. Default: 'puppet.<%= metric %>.<%= hostname %>'.
#
# === Examples
#
# To enable, enable pluginsync and reports on your master and clients in
# puppet.conf:
#
#   [master]
#   report = true
#   reports = statsd
#   pluginsync = true
#
#   [agent]
#   report = true
#   pluginsync = true
#
# ..and include the class:
#
#   class { 'puppet_statsd':
#     statsd_host => 'tungsten.eqiad.wmnet',
#   }
#
class puppet_statsd(
    $statsd_host,
    $statsd_port   = 8125,
    $metric_format = 'puppet.<%= metric %>.<%= hostname %>'
) {
    file { "${::puppet_config_dir}/statsd.yaml":
        content => template('puppet_statsd/statsd.yaml.erb'),
    }
}
