# == Define: prometheus::server
#
# The prometheus server takes care of 'scraping' (polling) a list of 'targets'
# via HTTP using one of
# https://prometheus.io/docs/instrumenting/exposition_formats/ and making the
# scraped metrics available for querying via HTTP.
#
# The scraped metrics will be stored locally in $storage_path for
# $storage_retention time and the HTTP interface will be served at
# http://$listen_address/$title.
#
# By default all values are based on the define title, in other words the
# prometheus server instance. This allows multi-tenancy for different
# prometheus usages.
#
# The default configuration includes a prometheus server scraping itself for
# metrics via its HTTP interface.
#
# = Parameters
#
# [*listen_address*]
#   Address to listen on, in the form [address]:port. Required to support
#   multiple instances listening on disjoint ports.
#
# [*scrape_interval*]
#   How often to scrape (poll) targets via HTTP.
#
# [*base_path*]
#   Where to store metrics/configuration/etc
#
# [*storage_retention*]
#   How long to save data for, old data will be expunged from disk eventually.
#   Overriden by `storage_retention_size`.
#
# [*storage_retention_size*]
#   Maximum number of bytes that can be stored for blocks. Units supported: KB, MB, GB, TB, PB. This flag is
#   experimental and can be changed in future releases, so use only if you really need it.
#   Will override `storage_retention`.
#
# [*global_config_extra*]
#   An hash with the global key => value prometheus configuration.
#
# [*scrape_configs_extra*]
#   A list of hashes used to configure additional scraping jobs. Each job has a
#   list of targets to scrape metrics from. Targets are usually configured
#   statically or dynamically via Service Discovery.
#
# [*rule_files_extra*]
#   A list of files (shell globs accepted) to look for recording and alerting
#   rules. See also https://prometheus.io/docs/querying/rules/ and
#   https://prometheus.io/docs/alerting/rules/. Note that defining alerting
#   rules won't trigger any notifications of any kind.
#
# [*alertmanagers*]
#   A list of host:port of alertmanagers to send alerts to.
#
# [*min_block_duration*]
#   The minimum duration of local TSDB blocks to consider for compaction
#
# [*max_block_duration*]
#   The maximum duration of local TSDB blocks to consider for compaction. Set
#   to the same value as min_block_duration to disable compactions (when using
#   Thanos only)

define prometheus::server (
    String                     $listen_address,
    String                     $scrape_interval        = '60s',
    Stdlib::Unixpath           $base_path              = "/srv/prometheus/${title}",
    String                     $storage_retention      = '730h',
    Optional[Stdlib::Datasize] $storage_retention_size = undef,
    String                     $storage_encoding       = '2',
    Integer                    $max_chunks_to_persist  = 524288,
    Integer                    $memory_chunks          = 1048576,
    Hash                       $global_config_extra    = {},
    Array                      $scrape_configs_extra   = [],
    Array                      $rule_files_extra       = [],
    Stdlib::HTTPUrl            $external_url           = "http://prometheus/${title}",
    String                     $min_block_duration     = '2h',
    String                     $max_block_duration     = '24h',
    Array                      $alertmanagers          = [],
    String                     $alerts_deploy_files    = '/srv/alerts/*.yaml',
) {
    include prometheus

    require_package('prometheus')

    $global_config_default = {
      'scrape_interval' => $scrape_interval,
    }
    $global_config = merge($global_config_default, $global_config_extra)
    $metrics_path = "${base_path}/metrics"
    $targets_path = "${base_path}/targets"
    $service_name = "prometheus@${title}"
    $rules_path = "${base_path}/rules"

    $scrape_configs_default = [
      {
        'job_name'      => 'prometheus',
        'metrics_path'  => "/${title}/metrics",
        'static_configs' => [
            { 'targets'  => [ $listen_address ] },
        ]
      },
      {
        'job_name'      => 'node',
        'file_sd_configs' => [
            { 'files'  => [ "${targets_path}/node_*.yml",
                            "${targets_path}/node_*.yaml" ] },
        ]
      },
    ]
    $scrape_configs = concat($scrape_configs_default, $scrape_configs_extra)

    $rule_files_default = [
      "${rules_path}/rules_*.yml",
      "${rules_path}/alerts_*.yml",
      $alerts_deploy_files,
    ]
    $validate_rules_cmd = '/usr/bin/promtool check rules %'
    $validate_config_cmd = '/usr/bin/promtool check config %'
    $rule_files = concat($rule_files_default, $rule_files_extra)

    $common_config = {
      'global'         => $global_config,
      'rule_files'     => $rule_files,
      'scrape_configs' => $scrape_configs,
    }

    if !empty($alertmanagers) {
      $alertmanager_config = [
        { 'targets' => $alertmanagers },
      ]
      $prometheus_config = $common_config + {
        'alerting' => {
          'alertmanagers'         => [
            { 'static_configs' => $alertmanager_config }
          ],
          'alert_relabel_configs' => [
            # Drop 'replica' label to get proper deduplication of alerts from HA pairs
            { 'regex' => 'replica', 'action' => 'labeldrop' },
          ],
        }
      }
    } else {
      $prometheus_config = $common_config
    }

    file { "${rules_path}/alerts_default.yml":
        ensure       => file,
        mode         => '0444',
        owner        => 'root',
        source       => 'puppet:///modules/prometheus/rules/alerts_default.yml',
        notify       => Exec["${service_name}-reload"],
        require      => File[$rules_path],
        validate_cmd => $validate_rules_cmd,
    }

    file { "${base_path}/prometheus.yml":
        ensure       => present,
        mode         => '0444',
        owner        => 'root',
        group        => 'root',
        notify       => Exec["${service_name}-reload"],
        content      => ordered_yaml($prometheus_config),
        validate_cmd => $validate_config_cmd,
    }

    file { [$base_path, $metrics_path, $targets_path, $rules_path]:
        ensure => directory,
        mode   => '0750',
        owner  => 'prometheus',
        group  => 'root',
    }
    File[$targets_path, $rules_path] {
        purge => true,
    }

    exec { "${service_name}-reload":
        command     => "/bin/systemctl reload ${service_name}",
        refreshonly => true,
    }

    # Avoid double declaration in the multiple-instance Prometheus case
    if !defined(Service['prometheus']) {
        # The default server instance must be stopped and masked to avoid conflicts.
        service { 'prometheus':
            ensure         => stopped,
        }
        systemd::mask { 'prometheus.service': }
    }

    $storage_retention_param = $storage_retention_size ? {
      undef   => "--storage.tsdb.retention ${storage_retention}",
      # Use a very high retention time so the size always gets triggered first
      default => "--storage.tsdb.retention.time 1000d --storage.tsdb.retention.size ${storage_retention_size.upcase()}",
    }

    systemd::service { $service_name:
        ensure         => present,
        restart        => true,
        content        => systemd_template('prometheus@'),
        service_params => {
            enable     => true,
            hasrestart => true,
        },
    }

    # Prometheus artifacts can sometimes cause odd monitoring artifacts -- missing data,
    # rate computations being lower than they should be, etc.
    # Report to IRC any Prometheis with too-low uptime.
    if $title == 'global' {
      $alert_description = "Prometheus ${::hostname}/${title} (or a Prometheus it scrapes) was restarted: beware possible monitoring artifacts"
    } else {
      $alert_description = "Prometheus ${::hostname}/${title} restarted: beware possible monitoring artifacts"
    }
    monitoring::check_prometheus { "uptime-${::hostname}-${service_name}":
      query           => 'time() - process_start_time_seconds{job="prometheus", instance=~"127\\.0\\.0\\.1:.*"}',
      method          => 'lt',
      warning         => 1800,
      critical        => 600,
      description     => $alert_description,
      prometheus_url  => "http://${::fqdn}/${title}",
      dashboard_links => ["https://grafana.wikimedia.org/d/GWvEXWDZk/prometheus-server?var-datasource=${::site} prometheus/${title}"],
      notes_link      => 'https://wikitech.wikimedia.org/wiki/Prometheus#Prometheus_was_restarted',
    }
}
