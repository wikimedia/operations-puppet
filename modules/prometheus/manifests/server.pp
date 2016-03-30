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

define prometheus::server (
    $listen_address,
    $scrape_interval = '60s',
    $base_path = "/srv/prometheus/${title}",
    $storage_retention = '4320h0m0s',
    $global_config_extra = {},
    $scrape_configs_extra = [],
    $rule_files_extra = [],
) {
    if ! os_version('debian >= jessie') {
        fail('only Debian jessie supported')
    }

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
        'target_groups' => [
            { 'targets'  => [ $listen_address ] },
        ]
      },
      {
        'job_name'      => 'node',
        'file_sd_configs' => [
            { 'names'  => [ "${targets_path}/node_*.yml" ] },
        ]
      },
    ]
    $scrape_configs = concat($scrape_configs_default, $scrape_configs_extra)

    $rule_files_default = [
      "${rules_path}/rules_*.conf",
      "${rules_path}/alerts_*.conf",
    ]
    $rule_files = concat($rule_files_default, $rule_files_extra)

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
        content => template('prometheus/prometheus.yml.erb'),
    }

    file { [$base_path, $metrics_path, $targets_path, $rules_path]:
        ensure => directory,
        mode   => '0750',
        owner  => 'prometheus',
        group  => 'prometheus',
    }

    exec { "${service_name}-reload":
        command     => "/bin/systemctl reload ${service_name}",
        onlyif      => "/usr/bin/promtool check-config ${base_path}/prometheus.yml && /usr/bin/promtool check-rules <%= @rule_files.join(' ') %>",
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
