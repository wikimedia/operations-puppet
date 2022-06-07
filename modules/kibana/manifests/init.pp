# SPDX-License-Identifier: Apache-2.0
# == Class: kibana
#
# Kibana is a JavaScript web application for visualizing log data and other
# types of time-stamped data. It integrates with Elasticsearch and Logstash.
#
# == Parameters:
# - $config_version: Kibana major version, used to decide which template to use to render /etc/kibana/kibana.yml
# - $default_app_id: Default landing page. You can specify files, scripts or
#     saved dashboards here. Default: '/dashboard/file/default.json'.
# - $enable_phatality: Defaults to true. Adds the phatality package to kibana
# - $logging_quiet: Set to true to suppress all logging output other than error messages.
# - $metrics_enabled: Enable/disable time series visual builder
# - $telemetry_enabled: Report cluster statistics back to elastic. Set to false to disable telemetry capabilities entirely
# - $newsfeed_enabled: Controls whether to enable the newsfeed system for the Kibana UI notification center. Set to false to disable the newsfeed system
# - $region_map_enabled: Enable/disable region map visualizations
# - $tile_map_enabled:  Enable/disable tile map visualizations
# - $timelion_enabled: Enable/disable timelion feature
#
# == Sample usage:
#
#   class { 'kibana':
#       default_app_id => 'dashboard/default',
#   }
#
class kibana (
    Enum['5', '6', '7'] $config_version,           #T275658
    String $default_app_id           = 'dashboard/default',
    String $kibana_package           = 'kibana',
    String $server_max_payload_bytes = '4194304',  #4MB (yes, this is a crazy limit, we need to reduce the number of fields)
    Boolean $enable_phatality        = true,
    Boolean $logging_quiet           = false,
    Boolean $metrics_enabled         = false,      #T255863
    Boolean $telemetry_enabled       = false,      #T259794
    Boolean $newsfeed_enabled        = false,      #T259794
    Boolean $timelion_enabled        = false,      #T259000
    Optional[Boolean] $region_map_enabled = undef, #T259000
    Optional[Boolean] $tile_map_enabled   = undef, #T259000
    Optional[Boolean] $vega_enabled       = false, #T274777
    Optional[String]  $kibana_index       = undef,
    Optional[Boolean] $enable_warnings    = undef,
) {
    package { 'kibana':
        ensure => 'present',
        name   => $kibana_package,
    }

    # ugly hack to solve https://phabricator.wikimedia.org/T192279 / https://github.com/elastic/kibana/issues/12915
    file { '/usr/share/kibana/optimize/bundles/stateSessionStorageRedirect.style.css':
        ensure => present,
        owner  => 'kibana',
        group  => 'kibana',
        mode   => '0664',
    }

    # https://phabricator.wikimedia.org/T275658 (need different kibana.yml based off ES version)
    $kibana_template_filepath = $config_version ? {
        '6'     => 'kibana/kibana_6.yml.erb',
        default => 'kibana/kibana.yml.erb',
    }

    file { '/etc/kibana/kibana.yml':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        content => template($kibana_template_filepath),
        mode    => '0444',
        require => Package['kibana'],
    }

    service { 'kibana':
        ensure  => running,
        enable  => true,
        require => [
            Package['kibana'],
            File['/etc/kibana/kibana.yml'],
        ],
    }

    if $enable_phatality {
      class { '::kibana::phatality': }
    }
}
