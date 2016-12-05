# Uses the prometheus module and generates the specific configuration
# needed for WMF production
class role::prometheus::ops {
    include base::firewall

    $targets_path = '/srv/prometheus/ops/targets'
    $rules_path = '/srv/prometheus/ops/rules'
    $storage_retention = hiera('prometheus::server::storage_retention', '4320h0m0s')

    $config_extra = {
        # All metrics will get an additional 'site' label when queried by
        # external systems (e.g. via federation)
        'external_labels' => {
            'site' => $::site,
        },
    }


    # Add one job for each of mysql 'group' (i.e. their broad function)
    # Each job will look for new files matching the glob and load the job
    # configuration automatically.
    $mysql_jobs = [
      {
        'job_name'        => 'mysql-core',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/mysql-core_*.yaml"] },
        ]
      },
      {
        'job_name'        => 'mysql-dbstore',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/mysql-dbstore_*.yaml"] },
        ]
      },
      {
        'job_name'        => 'mysql-labs',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/mysql-labs_*.yaml"] },
        ]
      },
      {
        'job_name'        => 'mysql-misc',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/mysql-misc_*.yaml"] },
        ]
      },
      {
        'job_name'        => 'mysql-parsercache',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/mysql-parsercache_*.yaml"] },
        ]
      },
    ]

    # Leave only backend hostname (no VCL UUID) from "varnish_backend" metrics
    # to avoid metric churn on VCL regeneration. See also T150479.
    $varnish_be_uuid_relabel = {
      'source_labels' => ['__name__', 'id'],
      'regex'         => 'varnish_backend_.+;root:[-a-f0-9]+\.(.*)',
      'target_label'  => 'id',
    }

    # one job per varnish cache 'role'
    $varnish_jobs = [
      {
        'job_name'        => 'varnish-text',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/varnish-text_*.yaml"] },
        ],
        'metric_relabel_configs' => [$varnish_be_uuid_relabel],
      },
      {
        'job_name'        => 'varnish-upload',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/varnish-upload_*.yaml"] },
        ],
        'metric_relabel_configs' => [$varnish_be_uuid_relabel],
      },
      {
        'job_name'        => 'varnish-maps',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/varnish-maps_*.yaml"] },
        ],
        'metric_relabel_configs' => [$varnish_be_uuid_relabel],
      },
      {
        'job_name'        => 'varnish-misc',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/varnish-misc_*.yaml"] },
        ],
        'metric_relabel_configs' => [$varnish_be_uuid_relabel],
      },
    ]

    # Job definition for memcache_exporter
    $memcached_jobs = [
      {
        'job_name'        => 'memcached',
        'file_sd_configs' => [
          { 'files' => [ "${targets_path}/memcached_*.yaml"] },
        ]
      },
    ]

    # Generate a list of hosts running memcached from Ganglia cluster definition
    prometheus::cluster_config{ "memcached_${::site}":
        dest    => "${targets_path}/memcached_${::site}.yaml",
        site    => $::site,
        cluster => 'memcached',
        port    => '9150',
        labels  => {}
    }

    prometheus::server { 'ops':
        storage_encoding     => '2',
        listen_address       => '127.0.0.1:9900',
        storage_retention    => $storage_retention,
        scrape_configs_extra => array_concat($mysql_jobs, $varnish_jobs, $memcached_jobs),
        global_config_extra  => $config_extra,
    }

    prometheus::web { 'ops':
        proxy_pass => 'http://localhost:9900/ops',
    }

    ferm::service { 'prometheus-web':
        proto  => 'tcp',
        port   => '80',
        srange => '$DOMAIN_NETWORKS',
    }

    File {
        backup  => false,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    # Query puppet exported resources and generate a list of hosts for
    # prometheus to poll metrics from. Ganglia::Cluster is used to generate the
    # mapping from cluster to a list of its members.
    $content = $::use_puppetdb ? {
        true => template('role/prometheus/node_site.yaml.erb'),
        default => generate('/usr/local/bin/prometheus-ganglia-gen',
        "--site=${::site}"),
    }
    file { "${targets_path}/node_site_${::site}.yaml":
        content => $content,
    }

    # Generate static placeholders for mysql jobs
    # this is only a temporary measure until we generate them from
    # a template and some exported resources
    file { "${targets_path}/mysql-core_${::site}.yaml":
        source => "puppet:///modules/role/prometheus/mysql-core_${::site}.yaml",
    }
    file { "${targets_path}/mysql-dbstore_${::site}.yaml":
        source => "puppet:///modules/role/prometheus/mysql-dbstore_${::site}.yaml",
    }
    file { "${targets_path}/mysql-misc_${::site}.yaml":
        source => "puppet:///modules/role/prometheus/mysql-misc_${::site}.yaml",
    }
    file { "${targets_path}/mysql-parsercache_${::site}.yaml":
        source => "puppet:///modules/role/prometheus/mysql-parsercache_${::site}.yaml",
    }
    file { "${targets_path}/mysql-labs_${::site}.yaml":
        source => "puppet:///modules/role/prometheus/mysql-labs_${::site}.yaml",
    }

    file { "${rules_path}/rules_ops.conf":
        source => 'puppet:///modules/role/prometheus/rules_ops.conf',
    }

    prometheus::varnish_2layer{ 'maps':
        targets_path => $targets_path,
        cache_name   => 'maps',
    }

    prometheus::varnish_2layer{ 'misc':
        targets_path => $targets_path,
        cache_name   => 'misc',
    }

    prometheus::varnish_2layer{ 'text':
        targets_path => $targets_path,
        cache_name   => 'text',
    }

    prometheus::varnish_2layer{ 'upload':
        targets_path => $targets_path,
        cache_name   => 'upload',
    }
}
