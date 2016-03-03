# == Class: service::configuration
#
# General configurations for services.
#
# === Parameters
#
# [*http_proxy*]
#   Full URL of the proxy to use
#
# [*statsd_host*]
#   StatsD host. Optional. Default: localhost
#
# [*statsd_port*]
#   StatsD port. Default: 8125
#
# [*logstash_host*]
#   GELF logging host. Default: localhost
#
# [*logstash_port*]
#   GELF logging port. Default: 12201
#
# [*log_dir*]
#   Local root log directory. The service's logs will be placed in its
#   subdirectory. Default: /var/log
#
# [*use_dev_pkgs*]
#   Whether the development packages declared for services should be installed.
#   Default: false
#
class service::configuration(
    $http_proxy    = undef,
    $statsd_host   = 'localhost',
    $statsd_port   = 8125,
    $logstash_host = 'localhost',
    $logstash_port = 12201,
    $log_dir       = '/var/log',
    $use_dev_pkgs  = false,
){
    # No op for now.
}
