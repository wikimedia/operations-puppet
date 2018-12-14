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
# [*outbound_tlsv1*]
#   Whether or not to enable TLSv1 for outbound TLS. Disabled by default (default: 0).
#
# [*outbound_tlsv1_1*]
#   Whether or not to enable TLSv1.1 for outbound TLS. Disabled by default (default: 0).
#
# [*outbound_tlsv1_2*]
#   Whether or not to enable TLSv1.2 for outbound TLS. Enabled by default (default: 1).
#
# [*outbound_tls_cipher_suite*]
#   The set of encryption, digest, authentication, and key exchange algorithms
#   which Traffic Server will use for outbound TLS connections. Default to the
#   empty string, in which case the values chosen by Traffic Server for
#   proxy.config.ssl.server.cipher_suite will be used. See
#   https://docs.trafficserver.apache.org/en/7.1.x/admin-guide/files/records.config.en.html
#
# [*outbound_tls_verify_origin*]
#   If true, validate origin server certificate. (default: true)
#
# [*outbound_tls_cacert_dirpath*]
#   Absolute path to the directory containing the file specified in
#   $outbound_tls_cacert_filename. (default: '/etc/ssl/certs/')
#
# [*outbound_tls_cacert_filename*]
#   If specified, the filename of the CA to trust for origin server certificate
#   validation. (default: '')
#
# [*enable_xdebug*]
#   Enable the XDebug plugin. (default: false)
#   https://docs.trafficserver.apache.org/en/latest/admin-guide/plugins/xdebug.en.html
#
# [*collapsed_forwarding*]
#   Enable the Collapsed Forwarding plugin. (default: true)
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
    Integer[0, 1] $outbound_tlsv1 = 0,
    Integer[0, 1] $outbound_tlsv1_1 = 0,
    Integer[0, 1] $outbound_tlsv1_2 = 1,
    String $outbound_tls_cipher_suite = '',
    Boolean $outbound_tls_verify_origin = true,
    String $outbound_tls_cacert_dirpath = '/etc/ssl/certs',
    String $outbound_tls_cacert_filename = '',
    Boolean $enable_xdebug = false,
    Boolean $collapsed_forwarding = true,
    String $global_lua_script = '',
    Array[Trafficserver::Mapping_rule] $mapping_rules = [],
    Array[Trafficserver::Caching_rule] $caching_rules = [],
    Array[Trafficserver::Storage_element] $storage = [],
    Array[Trafficserver::Log_format] $log_formats = [],
    Array[Trafficserver::Log_filter] $log_filters = [],
    Array[Trafficserver::Log] $logs = [],
) {

    ## Packages
    $ext_pkgs = [ 'trafficserver-experimental-plugins' ]

    package { 'trafficserver':
        ensure => present,
    }

    package { $ext_pkgs:
        ensure => present,
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

    ## Config files
    file {
        default:
          * => {
              owner  => $user,
              mode   => '0400',
              notify => Service['trafficserver'],
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
