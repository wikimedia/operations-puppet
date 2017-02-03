# == Class: role::prometheus::beta
#
# This class provides a Prometheus server used to monitor Beta
# (deployment-prep) labs project.
#
# filtertags: labs-project-deployment-prep

class role::prometheus::beta {
    $targets_path = '/srv/prometheus/beta/targets'
    $rules_path = '/srv/prometheus/beta/rules'

    # one job per varnish cache 'role'
    $varnish_jobs = [
      {
        'job_name'        => 'varnish-text',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/varnish-text_*.yaml"] },
        ]
      },
      {
        'job_name'        => 'varnish-upload',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/varnish-upload_*.yaml"] },
        ]
      },
    ]

    $mysql_jobs = [
      {
        'job_name'        => 'mysql-core',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/mysql-core_*.yaml"] },
        ]
      },
    ]

    $cassandra_jobs = [
      {
        'job_name'        => 'cassandra-restbase',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/cassandra-restbase_*.yaml"] },
        ]
      },
    ]

    $web_jobs = [
      {
        'job_name'        => 'apache',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/apache_*.yaml"] },
        ]
      },
      {
        'job_name'        => 'hhvm',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/hhvm_*.yaml"] },
        ]
      },
      {
        'job_name'        => 'memcache',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/memcache_*.yaml"] },
        ]
      },
    ]

    prometheus::server { 'beta':
        listen_address       => '127.0.0.1:9903',
        scrape_configs_extra => array_concat($varnish_jobs, $mysql_jobs, $web_jobs,
            $cassandra_jobs),
    }

    prometheus::web { 'beta':
        proxy_pass => 'http://127.0.0.1:9903/beta',
    }

    file { "${rules_path}/rules_beta.conf":
        source => 'puppet:///modules/role/prometheus/rules_beta.conf',
    }

    file { "${rules_path}/alerts_beta.conf":
        source => 'puppet:///modules/role/prometheus/alerts_beta.conf',
    }

    $targets_file = "${targets_path}/node_project.yml"

    include ::prometheus::scripts

    cron { 'prometheus_labs_project_targets':
        ensure  => present,
        command => "/usr/local/bin/prometheus-labs-targets > ${targets_file}.$$ && mv ${targets_file}.$$ ${targets_file}",
        minute  => '*/10',
        hour    => '*',
        user    => 'prometheus',
    }
}
