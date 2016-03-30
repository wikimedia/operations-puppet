# == Class: prometheus::server
#
# The prometheus server takes care of 'scraping' (polling) a list of 'targets'
# via HTTP using one of
# https://prometheus.io/docs/instrumenting/exposition_formats/ and making the
# scraped metrics available for querying. Metrics will be stored locally in
# $storage_path for $storage_retention time.
#
# The shipped configuration below includes prometheus server scraping itself
# for metrics on localhost:9090.

class prometheus::server (
    $scrape_interval = '60s',
    $storage_path = '/srv/prometheus',
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

    $scrape_configs_default = [
      {
        'job_name'      => 'prometheus',
        'target_groups' => [
            { 'targets'  => [ 'localhost:9090' ] },
        ]
      },
      {
        'job_name'      => 'node',
        'file_sd_configs' => [
            { 'names'  => [ '/etc/prometheus/targets/node_*.yml' ] },
        ]
      },
    ]
    $scrape_configs = concat($scrape_configs_default, $scrape_configs_extra)

    $rule_files_default = [
      '/etc/prometheus/rules/rules_*.conf',
      '/etc/prometheus/rules/alerts_*.conf',
    ]
    $rule_files = concat($rule_files_default, $rule_files_extra)

    file { '/etc/prometheus/rules/alerts_default.conf':
        ensure  => file,
        mode    => '0444',
        owner   => 'root',
        source  => 'puppet:///modules/prometheus/etc/prometheus/alerts_default.conf',
        notify  => Exec['prometheus-reload'],
        require => File['/etc/prometheus/rules'],
    }

    file { '/etc/prometheus/prometheus.yml':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        notify  => Exec['prometheus-reload'],
        content => template('prometheus/etc/prometheus/prometheus.yml.erb'),
    }

    file { '/etc/default/prometheus':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        notify  => Service['prometheus'],
        content => template('prometheus/etc/default/prometheus.erb'),
    }

    file { $storage_path:
        ensure => directory,
        mode   => '0750',
        owner  => 'prometheus',
        group  => 'prometheus',
    }

    file { '/etc/prometheus/rules':
        ensure => directory,
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    # output all nova instances for the current labs project as prometheus
    # 'targets'
    file { '/usr/local/bin/prometheus-labs-targets':
        ensure => file,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-labs-targets',
    }

    exec { 'prometheus-reload':
        command     => '/bin/systemctl reload prometheus',
        refreshonly => true,
    }

    base::service_unit { 'prometheus':
        ensure         => present,
        systemd        => true,
        service_params => {
            enable     => true,
            hasrestart => true,
        },
    }
}
