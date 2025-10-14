# SPDX-License-Identifier: Apache-2.0
# == Class: opensearch_dashboards
#
# OpenSearch Dashboards is a JavaScript web application for visualizing log data and other
# types of time-stamped data. It integrates with Elasticsearch and Logstash.
#
# == Parameters:
# - $version: This is a semantic version number x.y.z and will be used to pin the package.
# - $default_app_id: Default landing page. You can specify files, scripts or
#     saved dashboards here. Default: '/dashboard/file/default.json'.
# - $enable_backups: Defaults to false. Enables dashboards data backup job
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
    Opensearch::SemVer $version                  = undef,
    String             $default_app_id           = 'dashboard/default',
    String             $server_max_payload_bytes = '4194304', # 4MB (yes, this is a crazy limit, we need to reduce the number of fields)
    Boolean            $enable_backups           = false,
    Boolean            $logging_quiet            = false,
    Boolean            $metrics_enabled          = false, # T255863
    Boolean            $telemetry_enabled        = false, # T259794
    Boolean            $newsfeed_enabled         = false, # T259794
    Boolean            $timelion_enabled         = false, # T259000
    Optional[Boolean]  $region_map_enabled       = undef, # T259000
    Optional[Boolean]  $tile_map_enabled         = undef, # T259000
    Optional[Boolean]  $vega_enabled             = false, # T274777
    Optional[String]   $index                    = undef,
    Optional[Boolean]  $enable_warnings          = undef,
) {
    # Check that the version of the package corresponds to a released version
    unless $version { fail('Please specify an opensearch_dashboards version to install') }

    package { 'opensearch-dashboards':
        ensure => $version,
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

    if $enable_backups {
        class { 'opensearch_dashboards::backups': }
    } else {
        class { 'opensearch_dashboards::backups':
            ensure => 'absent'
        }
    }
}
