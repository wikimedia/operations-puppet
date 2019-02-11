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
# [*alertmanager_url*]
#   An url where alertmanager is listening for alerts. host:port when using Prometheus v2
#
# [*prometheus_v2*]
#   Whether to use Prometheus v2 config / command line options.

define prometheus::server (
    $listen_address,
    $scrape_interval = '60s',
    $base_path = "/srv/prometheus/${title}",
    $storage_retention = '730h',
    $storage_encoding = '2',
    $max_chunks_to_persist = '524288',
    $memory_chunks = '1048576',
    $global_config_extra = {},
    $scrape_configs_extra = [],
    $rule_files_extra = [],
    $alertmanager_url = undef,
    $external_url = "http://prometheus/${title}",
    $prometheus_v2 = false,
) {
    include ::prometheus

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

    if $prometheus_v2 {
      $rule_files_default = [
        "${rules_path}/rules_*.yml",
        "${rules_path}/alerts_*.yml",
      ]
      $validate_rules_cmd = '/usr/bin/promtool check rules %'
      $validate_config_cmd = '/usr/bin/promtool check config %'
    } else {
      $rule_files_default = [
        "${rules_path}/rules_*.conf",
        "${rules_path}/alerts_*.conf",
      ]
      $validate_rules_cmd = '/usr/bin/promtool check-rules %'
      $validate_config_cmd = '/usr/bin/promtool check-config %'
    }
    $rule_files = concat($rule_files_default, $rule_files_extra)

    $common_config = {
      'global'         => $global_config,
      'rule_files'     => $rule_files,
      'scrape_configs' => $scrape_configs,
    }

    if $prometheus_v2 and $alertmanager_url {
      # Prometheus v2 expects an hostport, not url
      # https://prometheus.io/docs/prometheus/latest/migration/#alertmanager-service-discovery
      validate_re($alertmanager_url, '^[a-zA-Z][-a-zA-Z0-9]+:[0-9]+$')
      $alertmanager_config = [
        { 'targets' =>  [ $alertmanager_url ] },
      ]
      $prometheus_config = $common_config + {
        'alerting' => {
          'alertmanagers' => [
            { 'static_configs' => $alertmanager_config }
          ],
        }
      }
    } else {
      $prometheus_config = $common_config
    }

    if $prometheus_v2 {
      file { "${rules_path}/alerts_default.yml":
          ensure       => file,
          mode         => '0444',
          owner        => 'root',
          source       => 'puppet:///modules/prometheus/rules/alerts_default.yml',
          notify       => Exec["${service_name}-reload"],
          require      => File[$rules_path],
          validate_cmd => $validate_rules_cmd,
      }
    } else {
      file { "${rules_path}/alerts_default.conf":
          ensure       => file,
          mode         => '0444',
          owner        => 'root',
          source       => 'puppet:///modules/prometheus/rules/alerts_default.conf',
          notify       => Exec["${service_name}-reload"],
          require      => File[$rules_path],
          validate_cmd => $validate_rules_cmd,
      }
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

    exec { "${service_name}-reload":
        command     => "/bin/systemctl reload ${service_name}",
        refreshonly => true,
    }

    # default server instance
    if !defined(Service['prometheus']) {
        service { 'prometheus':
            ensure => stopped,
        }
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
