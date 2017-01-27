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

define prometheus::server (
    $listen_address,
    $scrape_interval = '60s',
    $base_path = "/srv/prometheus/${title}",
    $storage_retention = '4320h0m0s',
    $storage_encoding = '1',
    $global_config_extra = {},
    $scrape_configs_extra = [],
    $rule_files_extra = [],
) {
    include ::prometheus

    requires_os('debian >= jessie')

    require_package('prometheus')

    $global_config_default = {
      'scrape_interval' => $scrape_interval,
    }
    $global_config = merge($global_config_default, $global_config_extra)
    $external_url = "http://prometheus/${title}"
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
      "${rules_path}/rules_*.conf",
      "${rules_path}/alerts_*.conf",
    ]
    $rule_files = concat($rule_files_default, $rule_files_extra)

    $prometheus_config = {
      'global'         => $global_config,
      'rule_files'     => $rule_files,
      'scrape_configs' => $scrape_configs,
    }

    file { "${rules_path}/alerts_default.conf":
        ensure  => file,
        mode    => '0444',
        owner   => 'root',
        source  => 'puppet:///modules/prometheus/rules/alerts_default.conf',
        notify  => Exec["${service_name}-reload"],
        require => File[$rules_path],
    }

    file { "${base_path}/prometheus.yml":
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        notify  => Exec["${service_name}-reload"],
        content => ordered_yaml($prometheus_config),
    }

    file { [$base_path, $metrics_path, $targets_path, $rules_path]:
        ensure => directory,
        mode   => '0750',
        owner  => 'prometheus',
        group  => 'root',
    }

    exec { "${service_name}-reload":
        command     => "/bin/systemctl reload ${service_name}",
        onlyif      => "/usr/bin/promtool check-config ${base_path}/prometheus.yml",
        refreshonly => true,
    }

    # default server instance
    if !defined(Service['prometheus']) {
        service { 'prometheus':
            ensure => stopped,
        }
    }

    base::service_unit { $service_name:
        ensure         => present,
        systemd        => true,
        template_name  => 'prometheus@',
        service_params => {
            enable     => true,
            hasrestart => true,
        },
    }
}
