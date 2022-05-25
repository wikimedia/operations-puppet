# SPDX-License-Identifier: Apache-2.0
# == Class: opensearch_dashboards
#
# OpenSearch Dashboards is a JavaScript web application for visualizing log data and other
# types of time-stamped data. It integrates with Elasticsearch and Logstash.
#
# == Parameters:
# - $config_version: OpenSearch Dashboards major version, used to decide which template to use to render /etc/opensearch-dashboards/opensearch_dashboards.yml
# - $default_app_id: Default landing page. You can specify files, scripts or
#     saved dashboards here. Default: '/dashboard/file/default.json'.
# - $enable_phatality: Defaults to true. Adds the phatality package to OpenSearch Dashboards
# - $logging_quiet: Set to true to suppress all logging output other than error messages.
# - $metrics_enabled: Enable/disable time series visual builder
# - $telemetry_enabled: Report cluster statistics back to elastic. Set to false to disable telemetry capabilities entirely
# - $newsfeed_enabled: Controls whether to enable the newsfeed system for the OpenSearch Dashboards UI notification center. Set to false to disable the newsfeed system
# - $region_map_enabled: Enable/disable region map visualizations
# - $tile_map_enabled:  Enable/disable tile map visualizations
# - $timelion_enabled: Enable/disable timelion feature
#
# == Sample usage:
#
#   class { 'opensearch_dashboards':
#       default_app_id => 'dashboard/default',
#   }
#
class opensearch_dashboards (
    Enum['1']         $config_version, # T275658
    String            $default_app_id           = 'dashboard/default',
    String            $package_name             = 'opensearch-dashboards',
    String            $server_max_payload_bytes = '4194304', # 4MB (yes, this is a crazy limit, we need to reduce the number of fields)
    Boolean           $enable_phatality         = true,
    Boolean           $logging_quiet            = false,
    Boolean           $metrics_enabled          = false, # T255863
    Boolean           $telemetry_enabled        = false, # T259794
    Boolean           $newsfeed_enabled         = false, # T259794
    Boolean           $timelion_enabled         = false, # T259000
    Optional[Boolean] $region_map_enabled       = undef, # T259000
    Optional[Boolean] $tile_map_enabled         = undef, # T259000
    Optional[Boolean] $vega_enabled             = false, # T274777
    Optional[String]  $index                    = undef,
    Optional[Boolean] $enable_warnings          = undef,
) {
    package { 'opensearch-dashboards':
        ensure => 'present',
        name   => $package_name,
    }

    file { '/etc/opensearch-dashboards/opensearch_dashboards.yml':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        content => template('opensearch_dashboards/opensearch_dashboards.yml.erb'),
        mode    => '0444',
        require => Package['opensearch-dashboards'],
    }

    service { 'opensearch-dashboards':
        ensure  => running,
        enable  => true,
        require => [
            Package['opensearch-dashboards'],
            File['/etc/opensearch-dashboards/opensearch_dashboards.yml'],
        ],
    }

    if $enable_phatality {
      class { '::opensearch_dashboards::phatality': }
    }
}
