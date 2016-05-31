# == Class: service::configuration
#
# General configurations for services.
#
# === Parameters
#
# [*mwapi_uri*]
#   The host/IP where to reach the MW API. Default:
#   http://api.svc.${::mw_primary}.wmnet/w/api.php
#
# [*restbase_uri*]
#   The host/IP where to reach RESTBase. Default:
#   http://restbase.svc.${::rb_site}.wmnet:7231
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
    $mwapi_uri     = "http://api.svc.${::mw_primary}.wmnet/w/api.php",
    $restbase_uri  = "http://restbase.svc.${::rb_site}.wmnet:7231",
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
