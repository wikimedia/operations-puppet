# == Class: service::configuration
#
# General configurations for services.
#
# === Parameters
#
# [*mwapi_uri*]
#   The host/IP where to reach the MW API. Default:
#   http://api-rw.discovery.wmnet/w/api.php
#
# [*restbase_uri*]
#   The host/IP where to reach RESTBase. Default:
#   http://restbase.discovery.wmnet:7231
#
# [*pdfrender_key*]
#   The access key to use when issuing requests to the PDF rendering service.
#   Default: 'secret'
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
# [*logstash_port_logback*]
#   Logback logging port. Default: 11514

# [*log_dir*]
#   Local root log directory. The service's logs will be placed in its
#   subdirectory. Default: /srv/log
#
# [*use_dev_pkgs*]
#   Whether the development packages declared for services should be installed.
#   Default: false
#
class service::configuration(
    $mwapi_uri     = 'http://api-rw.discovery.wmnet/w/api.php',
    $restbase_uri  = 'http://restbase.discovery.wmnet:7231',
    $pdfrender_key = 'secret',
    $http_proxy    = undef,
    $statsd_host   = 'localhost',
    $statsd_port   = 8125,
    $logstash_host = hiera('logstash_host', 'localhost'),
    $logstash_port = hiera('logstash_gelf_port', 12201),
    $logstash_port_logback = hiera('logstash_logback_port', 11514),
    $log_dir       = '/srv/log',
    $use_dev_pkgs  = false,
){

    file { $log_dir:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

}
