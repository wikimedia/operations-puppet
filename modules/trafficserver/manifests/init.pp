# == Class: trafficserver
#
# This module provisions Apache Traffic Server -- a fast, scalable caching
# proxy.
#
# === Logging
#
# ATS event logs can be written to ASCII files, binary files, or named pipes.
# Event logs are described here:
# https://docs.trafficserver.apache.org/en/latest/admin-guide/logging/understanding.en.html#event-logs
#
# === Parameters
#
# [*user*]
#   Run trafficserver as this user (default: 'trafficserver').
#
# [*port*]
#   Bind trafficserver to this port (default: 8080).
#
# [*outbound_tls_settings*]
#   Outbound TLS settings. (default: undef).
#   for example:
#   {
#       common => {
#           cipher_suite   => '-ALL:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384',
#           enable_tlsv1   => 0,
#           enable_tlsv1_1 => 0,
#           enable_tlsv1_2 => 1,
#           enable_tlsv1_3 => 1,
#       },
#       verify_origin   => true,
#       cacert_dirname  => '/etc/ssl/certs',
#       cacert_filename => 'Puppet_Internal_CA.pem',
#   }
# check the type definitions for more detailed information
#
# [*enable_xdebug*]
#   Enable the XDebug plugin. (default: false)
#   https://docs.trafficserver.apache.org/en/latest/admin-guide/plugins/xdebug.en.html
#
# [*collapsed_forwarding*]
#   Enable the Collapsed Forwarding plugin. (default: false)
#   https://docs.trafficserver.apache.org/en/latest/admin-guide/plugins/collapsed_forwarding.en.html
#
# [*global_lua_script*]
#   The name of the global Lua script to define in plugin.config. (default: '').
#
# [*mapping_rules*]
#   An array of Trafficserver::Mapping_rules, each representing a mapping rule. (default: []).
#   See https://docs.trafficserver.apache.org/en/latest/admin-guide/files/remap.config.en.html
#
# [*caching_rules*]
#   An array of Trafficserver::Caching_rules, each representing a caching rule. (default: []).
#   See https://docs.trafficserver.apache.org/en/latest/admin-guide/files/cache.config.en.html
#
# [*storage*]
#   An array of Trafficserver::Storage_elements. (default: []).
#
#   Partitions can be specified by setting the 'devname' key, while files or
#   directories use 'pathname'. For example:
#
#     { 'devname'  => 'sda3' }
#     { 'pathname' => '/srv/storage/', 'size' => '10G' }
#
#   See https://docs.trafficserver.apache.org/en/latest/admin-guide/files/storage.config.en.html
#
# [*ram_cache_size*]
#   The amount of memory in bytes to reserve for RAM cache. Traffic Server
#   automatically determines the RAM cache size if this value is not specified
#   or set to -1. (default: -1)
#   See https://docs.trafficserver.apache.org/en/latest/admin-guide/files/records.config.en.html
#
# [*log_formats*]
#   An array of Trafficserver::Log_formats. (default: []).
#   See https://docs.trafficserver.apache.org/en/latest/admin-guide/files/logging.yaml.en.html
#
# [*log_filters*]
#   An array of Trafficserver::Log_filters. (default: []).
#   See https://docs.trafficserver.apache.org/en/latest/admin-guide/files/logging.yaml.en.html
#
# [*logs*]
#   An array of Trafficserver::Logs. (default: []).
#   See https://docs.trafficserver.apache.org/en/latest/admin-guide/files/logging.yaml.en.html
#
# [*error_page*]
#   A string containing the error page to deliver to clients when there are
#   problems with the HTTP transactions. (default: '<html><head><title>Error</title></head><body><p>Something went wrong</p></body></html>').
#   See https://docs.trafficserver.apache.org/en/latest/admin-guide/monitoring/error-messages.en.html#body-factory
#
# === Examples
#
#  class { 'trafficserver':
#    user          => 'trafficserver',
#    port          => 80,
#    log_mode      => 'ascii',
#    log_format    => 'squid',
#    log_filename  => 'access',
#    mapping_rules => [ { 'type'        => 'map',
#                         'target'      => 'http://grafana.wikimedia.org/',
#                         'replacement' => 'http://krypton.eqiad.wmnet/', },
#                       { 'type'        => 'map',
#                         'target'      => '/',
#                         'replacement' => 'http://deployment-mediawiki05.deployment-prep.eqiad.wmflabs/' }, ],
#    caching_rules => [ { 'primary_destination' => 'dest_domain',
#                         'value'               => 'grafana.wikimedia.org',
#                         'action'              => 'never-cache' }, ],
#    storage       => [ { 'pathname' => '/srv/storage/', 'size' => '10G' },
#                       { 'devname'  => 'sda3', 'volume' => 1 },
#                       { 'devname'  => 'sdb3', 'volume' => 2, 'id' => 'cache.disk.1' }, ],
#  }
#
class trafficserver(
    String $user = 'trafficserver',
    Wmflib::IpPort $port = 8080,
    Optional[Trafficserver::Outbound_TLS_settings] $outbound_tls_settings = undef,
    Boolean $enable_xdebug = false,
    Boolean $collapsed_forwarding = false,
    String $global_lua_script = '',
    Array[Trafficserver::Mapping_rule] $mapping_rules = [],
    Array[Trafficserver::Caching_rule] $caching_rules = [],
    Array[Trafficserver::Storage_element] $storage = [],
    Integer $ram_cache_size = -1,
    Array[Trafficserver::Log_format] $log_formats = [],
    Array[Trafficserver::Log_filter] $log_filters = [],
    Array[Trafficserver::Log] $logs = [],
    String $error_page = '<html><head><title>Error</title></head><body><p>Something went wrong</p></body></html>',
) {

    ## Packages
    $ext_pkgs = [ 'trafficserver-experimental-plugins' ]

    package { 'trafficserver':
        ensure  => present,
        require => Exec['apt-get update'],
    }

    package { $ext_pkgs:
        ensure  => present,
        require => Exec['apt-get update'],
    }

    # Change the ownership of all raw devices so that the trafficserver user
    # has read/write access to them
    $storage.each |Trafficserver::Storage_element $element| {
        if has_key($element, 'devname') {
            udev::rule { $element['devname']:
                content => template('trafficserver/udev_storage.rules.erb'),
            }
        }
    }

    $error_template_path = '/etc/trafficserver/error_template'
    file {
      [$error_template_path, "${error_template_path}/default"]:
        ensure  => directory,
        owner   => $user,
        mode    => '0755',
        require => Package['trafficserver'],
    }

    ## Config files
    file {
        default:
          * => {
              owner   => $user,
              mode    => '0400',
              require => Package['trafficserver'],
              notify  => Service['trafficserver'],
          };

        '/etc/trafficserver/records.config':
          content => template('trafficserver/records.config.erb'),;

        '/etc/trafficserver/remap.config':
          content => template('trafficserver/remap.config.erb'),;

        '/etc/trafficserver/cache.config':
          content => template('trafficserver/cache.config.erb'),;

        '/etc/trafficserver/ip_allow.config':
          content => template('trafficserver/ip_allow.config.erb'),;

        '/etc/trafficserver/storage.config':
          content => template('trafficserver/storage.config.erb'),;

        '/etc/trafficserver/plugin.config':
          content => template('trafficserver/plugin.config.erb'),;

        '/etc/trafficserver/logging.yaml':
          content => template('trafficserver/logging.yaml.erb');

        '/etc/trafficserver/healtchecks.config':
          # Response body can be changed by pointing to a text file with actual
          # contents instead of /dev/null
          content => '/check /dev/null text/plain 200 403',;

        "${error_template_path}/default/.body_factory_info":
          # This file just needs to be there or ATS will refuse loading any
          # template
          content => '',
          require => File[$error_template_path];

        "${error_template_path}/default/default":
          content => $error_page,
          require => File[$error_template_path];
    }

    ## Service
    systemd::service { 'trafficserver':
        content        => init_template('trafficserver', 'systemd_override'),
        override       => true,
        restart        => true,
        service_params => {
            restart    => 'systemctl reload trafficserver',
        },
        subscribe      => Package[$ext_pkgs],
    }
}
