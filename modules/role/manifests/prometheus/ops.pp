class role::prometheus::ops {
    include base::firewall

    $targets_path = '/srv/prometheus/ops/targets'

    # Add one job for each of mysql 'group' (i.e. their broad function)
    $mysql_jobs = [
        {
          'job_name'      => 'mysql-core',
          'file_sd_configs' => [
              { 'names'  => [ "${targets_path}/mysql-core_*.yaml"] },
          ]
        },
        {
          'job_name'      => 'mysql-dbstore',
          'file_sd_configs' => [
              { 'names'  => [ "${targets_path}/mysql-dbstore_*.yaml"] },
          ]
        },
        {
          'job_name'      => 'mysql-labs',
          'file_sd_configs' => [
              { 'names'  => [ "${targets_path}/mysql-labs_*.yaml"] },
          ]
        },
        {
          'job_name'      => 'mysql-misc',
          'file_sd_configs' => [
              { 'names'  => [ "${targets_path}/mysql-misc_*.yaml"] },
          ]
        },
        {
          'job_name'      => 'mysql-parsercache',
          'file_sd_configs' => [
              { 'names'  => [ "${targets_path}/mysql-parsercache_*.yaml"] },
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

    # Query puppet exported resources and generate a list of hosts for
    # prometheus to poll metrics from. Ganglia::Cluster is used to generate the
    # mapping from cluster to a list of its members.
    file { "/srv/prometheus/ops/targets/node_site_${::site}.yaml":
        content => generate('/usr/local/bin/prometheus-ganglia-gen',
                            "--site=${::site}"),
        backup  => false,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }
}
