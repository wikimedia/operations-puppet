class profile::wdqs (
    String $logstash_host = hiera('logstash_host'),
    Boolean $use_git_deploy = hiera('profile::wdqs::use_git_deploy'),
    String $package_dir = hiera('profile::wdqs::package_dir'),
    String $data_dir = hiera('profile::wdqs::data_dir'),
    String $endpoint = hiera('profile::wdqs::endpoint'),
    String $blazegraph_options = hiera('profile::wdqs::blazegraph_options'),
    String $blazegraph_heap_size = hiera('profile::wdqs::blazegraph_heap_size'),
    String $blazegraph_config_file = hiera('profile::wdqs::blazegraph_config_file'),
    String $updater_options = hiera('profile::wdqs::updater_options'),
    Array[String] $nodes = hiera('profile::wdqs::nodes'),
    Boolean $use_kafka_for_updates = hiera('profile::wdqs::use_kafka_for_updates'),
    Array[String] $cluster_names = hiera('profile::wdqs::cluster_names'),
    String $rc_options = hiera('profile::wdqs::rc_updater_options'),
    Boolean $enable_ldf = hiera('profile::wdqs::enable_ldf'),
    Array[String] $prometheus_nodes = hiera('prometheus_nodes'),
    String $contact_groups = hiera('contactgroups', 'admins'),
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


    if( $use_kafka_for_updates ) {
        $kafka_brokers = kafka_config('jumbo-eqiad')['brokers']['string']
        if( count($cluster_names) > 0 ) {
            $joined_cluster_names = join($cluster_names, ',')
            $extra_updater_options = "--kafka ${kafka_brokers} --consumer ${::hostname} --clusters ${joined_cluster_names}"
        } else {
            $extra_updater_options = "--kafka ${kafka_brokers} --consumer ${::hostname}"
        }
    } else {
        $extra_updater_options = $rc_options
    }

    class { 'wdqs::updater':
        options        => "${updater_options} -- ${extra_updater_options}",
        logstash_host  => $logstash_host,
        extra_jvm_opts => "-javaagent:${prometheus_agent_path}=${prometheus_agent_port}:${prometheus_agent_config}",
        require        => Profile::Prometheus::Jmx_exporter['wdqs_updater'],
    }

    # Service Web proxy
    class { '::wdqs::gui':
        logstash_host  => $logstash_host,
        package_dir    => $package_dir,
        data_dir       => $data_dir,
        use_git_deploy => $use_git_deploy,
        enable_ldf     => $enable_ldf,
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
    class { '::wdqs::monitor::services':
        contact_groups => $contact_groups,
    }

}
