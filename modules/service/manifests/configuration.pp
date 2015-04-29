# == Class: service::configuration
#
# General configurations for services.
#
# === Parameters
#
# [*http_proxy*]
#   Full URL of the proxy to use
#
# [*no_proxy_list*]
#   List of domains fow which $http_proxy should not be used
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

class service::configuration(
    $http_proxy    = undef,
    $no_proxy_list = undef,
    $statsd_host   = 'localhost',
    $statsd_port   = 8125,
    $logstash_host = 'localhost',
    $logstash_port = 11201,
    $log_dir   = '/var/log',
    ){
    # No op for now.
}
