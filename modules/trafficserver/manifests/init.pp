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
# [*synthetic_port*]
#   The synthetic healthcheck port (default: 8083).
#
# [*mgmt_port*]
#   The port used for internal communication between traffic_manager and
#   traffic_server processes (default: 8084).
#
# [*log_method*]
#   The method used to produce event logs. Valid options are: 'ascii',
#   'binary', 'pipe' (default: 'pipe').
#   See https://docs.trafficserver.apache.org/en/latest/admin-guide/files/logging.config.en.html#logs
#
# [*log_format*]
#   The format to be used for event log entries. Valid options are: 'squid',
#   'extended' (default: 'squid').
#
# [*log_filename*]
#   The filename to use for event log entries. (default: 'event').
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
# [*mapping_rules*]
#   An array of Trafficserver::Mapping_rules, each representing a mapping rule. (default: []).
#   See https://docs.trafficserver.apache.org/en/latest/admin-guide/files/remap.config.en.html
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
# === Examples
#
#  class { 'trafficserver':
#    user          => 'trafficserver',
#    port          => 80,
#    log_method    => 'ascii',
#    log_format    => 'squid',
#    log_filename  => 'access',
#    mapping_rules => [ { 'type'        => 'map',
#                         'target'      => 'http://grafana.wikimedia.org/',
#                         'replacement' => 'http://krypton.eqiad.wmnet/', },
#                       { 'type'        => 'map',
#                         'target'      => '/',
#                         'replacement' => 'http://deployment-mediawiki05.deployment-prep.eqiad.wmflabs/' }, ],
#    storage       => [ { 'pathname' => '/srv/storage/', 'size' => '10G' },
#                       { 'devname'  => 'sda3', 'volume' => 1 },
#                       { 'devname'  => 'sdb3', 'volume' => 2, 'id' => 'cache.disk.1' }, ],
#  }
#
class trafficserver(
    String $user = 'trafficserver',
    Wmflib::IpPort $port = 8080,
    Wmflib::IpPort $synthetic_port = 8083,
    Wmflib::IpPort $mgmt_port = 8084,
    Enum['ascii', 'binary', 'pipe'] $log_method = 'pipe',
    Enum['squid', 'extended'] $log_format = 'squid',
    String $log_filename = 'event',
    Integer[0, 1] $outbound_tlsv1 = 0,
    Integer[0, 1] $outbound_tlsv1_1 = 0,
    Integer[0, 1] $outbound_tlsv1_2 = 1,
    String $outbound_tls_cipher_suite = '',
    Array[Trafficserver::Mapping_rule] $mapping_rules = [],
    Array[Trafficserver::Storage_element] $storage = [],
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

        '/etc/trafficserver/ip_allow.config':
          content => template('trafficserver/ip_allow.config.erb'),;

        '/etc/trafficserver/storage.config':
          content => template('trafficserver/storage.config.erb'),;

        '/etc/trafficserver/plugin.config':
          content => template('trafficserver/plugin.config.erb'),;

        '/etc/trafficserver/logging.config':
          content => template('trafficserver/logging.config.erb');

        '/etc/trafficserver/healtchecks.config':
          # Response body can be changed by pointing to a text file with actual
          # contents instead of /dev/null
          content => '/check /dev/null text/plain 200 403',;
    }

    ## Service
    systemd::service { 'trafficserver':
        ensure         => present,
        content        => systemd_template('trafficserver'),
        restart        => true,
        service_params => {
            restart    => 'systemctl reload trafficserver',
        },
        subscribe      => Package[$ext_pkgs],
    }
}
