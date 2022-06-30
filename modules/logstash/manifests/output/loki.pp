# SPDX-License-Identifier: Apache-2.0
# = Define: logstash::output::loki
#
# Output logstash messages to a Loki instance.
#
# == Parameters:
#
# - $ensure: Whether the config should exist.
# - $guard_condition: Logstash condition to require to pass events to output.
# - $host: Loki server.
# - $path: The Loki endpoint path.
# - $plugin_id: Name associated for Logstash metrics.
# - $port: Loki http port.
# - $priority: Configuration loading priority.
# - $scheme: Loki url scheme.
#
# == Sample usage:
#
#   logstash::output::loki { 'loki':
#       host => 'loki1001',
#   }
define logstash::output::loki(
  Wmflib::Ensure                             $ensure          = present,
  Optional[String]                           $guard_condition = undef,
  Variant[Stdlib::IP::Address, Stdlib::Fqdn] $host            = '127.0.0.1',
  Stdlib::Unixpath                           $path            = '/loki/api/v1/push',
  String                                     $plugin_id       = "output/loki/${title}",
  Stdlib::Port                               $port            = 3100,
  Integer                                    $priority        = 90,
  Enum['http', 'https']                      $scheme          = 'http',
) {
  $url = "${scheme}://${host}:${port}${path}"

  logstash::conf { "output-loki-${title}":
    ensure   => $ensure,
    content  => template('logstash/output/loki.erb'),
    priority => $priority,
  }
}
