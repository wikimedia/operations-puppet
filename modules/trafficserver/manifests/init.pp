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
# [*mapping_rules*]
#   An array of Trafficserver::Mapping_rules, each representing a mapping rule. (default: []).
#   See https://docs.trafficserver.apache.org/en/latest/admin-guide/files/remap.config.en.html
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
#                         'replacement' => 'http://deployment-mediawiki05.deployment-prep.eqiad.wmflabs/' }, ]
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
    Array[Trafficserver::Mapping_rule] $mapping_rules = [],
) {

    ## Packages
    $ext_pkgs = [ 'trafficserver-experimental-plugins' ]

    package { 'trafficserver':
        ensure => present,
    }

    package { $ext_pkgs:
        ensure => present,
    }

    ## Config files
    exec { 'verify_config':
        command     => '/usr/bin/traffic_server -C verify_config',
        refreshonly => true,
    }

    file {
        default:
          * => {
              owner  => $user,
              mode   => '0400',
              notify => [ Exec['verify_config'], Service['trafficserver'] ],
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
        service_params => {
            hasrestart => true,
            restart    => '/usr/bin/traffic_ctl config reload',
        },
        subscribe      => Package[$ext_pkgs],
    }
}
