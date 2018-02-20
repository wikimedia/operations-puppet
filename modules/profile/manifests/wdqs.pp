class profile::wdqs (
    $logstash_host = hiera('logstash_host'),
    $use_git_deploy = hiera('profile::wdqs::use_git_deploy'),
    $package_dir = hiera('profile::wdqs::package_dir'),
    $data_dir = hiera('profile::wdqs::data_dir'),
    $endpoint = hiera('profile::wdqs::endpoint'),
    $blazegraph_options = hiera('profile::wdqs::blazegraph_options'),
    $blazegraph_heap_size = hiera('profile::wdqs::blazegraph_heap_size'),
    $blazegraph_config_file = hiera('profile::wdqs::blazegraph_config_file'),
    $additional_updater_options = hiera('profile::wdqs::additional_updater_options'),
    $nodes = hiera('profile::wdqs::nodes'),
    $use_kafka_for_updates = hiera('profile::wdqs::use_kafka_for_updates'),
    $cluster_names = hiera('profile::wdqs::cluster_names'),
    $prometheus_nodes = hiera('prometheus_nodes'),
) {
    require ::profile::prometheus::blazegraph_exporter

    $nagios_contact_group = 'admins,wdqs-admins'

    # Install services - both blazegraph and the updater
    class { '::wdqs':
        use_git_deploy         => $use_git_deploy,
        package_dir            => $package_dir,
        data_dir               => $data_dir,
        endpoint               => $endpoint,
        blazegraph_options     => $blazegraph_options,
        blazegraph_heap_size   => $blazegraph_heap_size,
        blazegraph_config_file => $blazegraph_config_file,
        logstash_host          => $logstash_host,
    }

    $prometheus_agent_path = '/usr/share/java/prometheus/jmx_prometheus_javaagent.jar'
    $prometheus_agent_port = '9101'
    $prometheus_agent_config = '/etc/wdqs/wdqs-updater-prometheus-jmx.yaml'

    # WDQS Updater service
    profile::prometheus::jmx_exporter { 'wdqs_updater':
        hostname         => $::hostname,
        port             => $prometheus_agent_port,
        prometheus_nodes => $prometheus_nodes,
        config_file      => $prometheus_agent_config,
        source           => 'puppet:///modules/profile/wdqs/wdqs-updater-prometheus-jmx.yaml',
    }

    $kafka_brokers = $use_kafka_for_updates ? {
        true    => kafka_config('jumbo-eqiad')['brokers']['array'],
        default => [],
    }

    class { 'wdqs::updater':
        options        => $additional_updater_options,
        kafka_brokers  => $kafka_brokers,
        cluster_names  => $cluster_names,
        logstash_host  => $logstash_host,
        extra_jvm_opts => "-javaagent:${prometheus_agent_path}=${prometheus_agent_port}:${prometheus_agent_config}",
        require        => Profile::Prometheus::Jmx_exporter['wdqs_updater'],
    }

    # Service Web proxy
    class { '::wdqs::gui':
        logstash_host => $logstash_host,
    }

    # Firewall
    ferm::service {
        'wdqs_http':
            proto => 'tcp',
            port  => '80';
        'wdqs_https':
            proto => 'tcp',
            port  => '443';
        'wdqs_internal_http':
            proto  => 'tcp',
            port   => '8888',
            srange => '$DOMAIN_NETWORKS';
        # temporary port to transfer data file between wdqs nodes via netcat
        'wdqs_file_transfer':
            proto  => 'tcp',
            port   => '9876',
            srange => inline_template("@resolve((<%= @nodes.join(' ') %>))");
    }

    # Monitoring
    class { '::wdqs::monitor::blazegraph': }
    class { '::wdqs::monitor::updater': }
    class { '::wdqs::monitor::services': }
}
