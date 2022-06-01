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
#   Address to listen on, in the form address:port. Required to support
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
# [*alerting_relabel_configs_extra*]
#   A list of additional rempa rules applied to alerts sent to Alertmanager.
#
# [*alertmanagers*]
#   A list of host:port of alertmanagers to send alerts to.
#
# [*alertmanager_discovery_extra*]
#   A list of additional Prometheus Service Discovery configurations used to
#   locate alertmanager instances.
#
# [*min_block_duration*]
#   The minimum duration of local TSDB blocks to consider for compaction
#
# [*max_block_duration*]
#   The maximum duration of local TSDB blocks to consider for compaction. Set
#   to the same value as min_block_duration to disable compactions (when using
#   Thanos only)

define prometheus::server (
    Pattern[/.+:[0-9]+$/]      $listen_address,
    String                     $scrape_interval                = '60s',
    Stdlib::Unixpath           $base_path                      = "/srv/prometheus/${title}",
    String                     $storage_retention              = '730h',
    Optional[Stdlib::Datasize] $storage_retention_size         = undef,
    String                     $storage_encoding               = '2',
    Integer                    $max_chunks_to_persist          = 524288,
    Integer                    $memory_chunks                  = 1048576,
    Hash                       $global_config_extra            = {},
    Array                      $scrape_configs_extra           = [],
    Array                      $rule_files_extra               = [],
    Array                      $alerting_relabel_configs_extra = [],
    Stdlib::HTTPUrl            $external_url                   = "http://prometheus.svc.${::site}.wmnet/${title}",
    String                     $min_block_duration             = '2h',
    String                     $max_block_duration             = '24h',
    Array                      $alertmanagers                  = [],
    Array                      $alertmanager_discovery_extra   = [],
    String                     $alerts_deploy_path             = '/srv/alerts',
) {
    include prometheus

    ensure_packages('prometheus')

    $global_config_default = {
      'scrape_interval' => $scrape_interval,
    }
    $global_config = merge($global_config_default, $global_config_extra)
    $metrics_path = "${base_path}/metrics"
    $targets_path = "${base_path}/targets"
    $service_name = "prometheus@${title}"
    $rules_path = "${base_path}/rules"

    $port = split($listen_address, ':')[1]

    $scrape_configs_default = [
      {
        'job_name'      => 'prometheus',
        'metrics_path'  => "/${title}/metrics",
        'static_configs' => [
            { 'targets'  => [ $listen_address ] },
        ],
        'relabel_configs' => [
          { 'target_label' => 'instance',
            'replacement'  => "${::hostname}:${port}",
          },
        ],
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
      "${alerts_deploy_path}/*.yaml",
      "${alerts_deploy_path}/${title}/*.yaml",
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
      $alertmanager_discovery_static = [
        {
          'static_configs' => [
            { 'targets' => $alertmanagers },
          ],
        },
      ]
    } else {
      $alertmanager_discovery_static = []
    }

    if !empty($alertmanager_discovery_static) or !empty($alertmanager_discovery_extra) {
      $alert_relabel_configs = [
        # Drop 'replica' label to get proper deduplication of alerts from HA pairs
        { 'regex' => 'replica', 'action' => 'labeldrop' },
        # Add 'source' label
        { 'target_label' => 'source', 'replacement' => 'prometheus', 'action' => 'replace' },
      ] + $alerting_relabel_configs_extra

      $prometheus_config = $common_config + {
        'alerting' => {
          'alertmanagers'         => $alertmanager_discovery_static + $alertmanager_discovery_extra,
          'alert_relabel_configs' => $alert_relabel_configs,
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
        content      => to_yaml($prometheus_config),
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
}
