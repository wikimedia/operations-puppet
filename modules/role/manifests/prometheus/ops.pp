# Uses the prometheus module and generates the specific configuration
# needed for WMF production
class role::prometheus::ops {
    include base::firewall

    $targets_path = '/srv/prometheus/ops/targets'
    $rules_path = '/srv/prometheus/ops/rules'

    # Add one job for each of mysql 'group' (i.e. their broad function)
    # Each job will look for new files matching the glob and load the job
    # configuration automatically.
    $mysql_jobs = [
      {
        'job_name'        => 'mysql-core',
        'file_sd_configs' => [
          { 'names' => [ "${targets_path}/mysql-core_*.yaml"] },
        ]
      },
      {
        'job_name'        => 'mysql-dbstore',
        'file_sd_configs' => [
          { 'names' => [ "${targets_path}/mysql-dbstore_*.yaml"] },
        ]
      },
      {
        'job_name'        => 'mysql-labs',
        'file_sd_configs' => [
          { 'names' => [ "${targets_path}/mysql-labs_*.yaml"] },
        ]
      },
      {
        'job_name'        => 'mysql-misc',
        'file_sd_configs' => [
          { 'names' => [ "${targets_path}/mysql-misc_*.yaml"] },
        ]
      },
      {
        'job_name'        => 'mysql-parsercache',
        'file_sd_configs' => [
          { 'names' => [ "${targets_path}/mysql-parsercache_*.yaml"] },
        ]
      },
    ]

    prometheus::server { 'ops':
        listen_address       => '127.0.0.1:9900',
        scrape_configs_extra => $mysql_jobs,
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
}
