class profile::wdqs::blazegraph(
    Stdlib::Unixpath $package_dir = hiera('profile::wdqs::package_dir', '/srv/deployment/wdqs/wdqs'),
    Stdlib::Unixpath $data_dir = hiera('profile::wdqs::data_dir', '/srv/wdqs'),
    Stdlib::Unixpath $log_dir = hiera('profile::wdqs::log_dir', '/var/log/wdqs'),
    String $logstash_host = hiera('logstash_host'),
    Stdlib::Port $logstash_json_port = hiera('logstash_json_lines_port'),
    String $endpoint = hiera('profile::wdqs::endpoint', 'https://query.wikidata.org'),
    String $heap_size = hiera('profile::wdqs::blazegraph_heap_size', '31g'),
    Boolean $use_deployed_config = hiera('profile::wdqs::blazegraph_use_deployed_config', false),
    Array[String] $options = hiera('profile::wdqs::blazegraph_options'),
    Array[String] $extra_jvm_opts = hiera('profile::wdqs::blazegraph_extra_jvm_opts'),
    Array[String] $prometheus_nodes = hiera('prometheus_nodes'),
    String $contact_groups = hiera('contactgroups', 'admins'),
    Integer[0] $lag_warning  = hiera('profile::wdqs::lag_warning', 1200),
    Integer[0] $lag_critical = hiera('profile::wdqs::lag_critical', 3600),
) {
    require ::profile::wdqs::common

    $username = 'blazegraph'
    $prometheus_agent_path = '/usr/share/java/prometheus/jmx_prometheus_javaagent.jar'
    $default_extra_jvm_opts = [
        '-XX:+UseNUMA',
        '-XX:+UnlockExperimentalVMOptions',
        '-XX:G1NewSizePercent=20',
        '-XX:+ParallelRefProcEnabled',
    ]

    $prometheus_agent_port_wdqs = 9102
    $prometheus_agent_config_wdqs = '/etc/wdqs/wdqs-blazegraph-prometheus-jmx.yaml'
    $prometheus_agent_port_categories = 9103
    $prometheus_agent_config_categories = '/etc/wdqs/wdqs-categories-prometheus-jmx.yaml'
    profile::prometheus::jmx_exporter {
        default:
            hostname         => $::hostname,
            prometheus_nodes => $prometheus_nodes,
            source           => 'puppet:///modules/profile/wdqs/wdqs-blazegraph-prometheus-jmx.yaml',
            ;
        'wdqs_blazegraph':
            port        => $prometheus_agent_port_wdqs,
            before      => Service['wdqs-blazegraph'],
            config_file => $prometheus_agent_config_wdqs,
            ;
        'wdqs_categories':
            port        => $prometheus_agent_port_categories,
            before      => Service['wdqs-categories'],
            config_file => $prometheus_agent_config_categories,
    }

    file { '/usr/local/bin/prometheus-blazegraph-exporter':
        ensure => present,
        source => 'puppet:///modules/wdqs/monitor/prometheus-blazegraph-exporter.py',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }
    prometheus::blazegraph_exporter { 'wdqs-blazegraph':
        blazegraph_port  => 9999,
        prometheus_port  => 9193,
        prometheus_nodes => $prometheus_nodes,
    }
    prometheus::blazegraph_exporter { 'wdqs-categories':
        blazegraph_port  => 9990,
        prometheus_port  => 9194,
        prometheus_nodes => $prometheus_nodes,
    }

    wdqs::blazegraph {
        default:
            package_dir         => $package_dir,
            data_dir            => $data_dir,
            logstash_host       => $logstash_host,
            logstash_json_port  => $logstash_json_port,
            log_dir             => $log_dir,
            username            => $username,
            options             => $options,
            use_deployed_config => $use_deployed_config,
            ;
        'wdqs-blazegraph':
            port             => 9999,
            config_file_name => 'RWStore.properties',
            heap_size        => $heap_size,
            extra_jvm_opts   => $default_extra_jvm_opts + $extra_jvm_opts +  "-javaagent:${prometheus_agent_path}=${prometheus_agent_port_wdqs}:${prometheus_agent_config_wdqs}"
            ;
        'wdqs-categories':
            port             => 9990,
            config_file_name => 'RWStore.categories.properties',
            heap_size        => '8g',
            extra_jvm_opts   => $default_extra_jvm_opts + $extra_jvm_opts +  "-javaagent:${prometheus_agent_path}=${prometheus_agent_port_categories}:${prometheus_agent_config_categories}"
    }

    class { 'wdqs::monitor::blazegraph':
        username       => $username,
        contact_groups => $contact_groups,
        lag_warning    => $lag_warning,
        lag_critical   => $lag_critical,
    }

    wdqs::monitor::blazegraph_instance {
        default:
            username       => $username,
            contact_groups => $contact_groups,
            ;
        'wdqs-blazegraph':
            port           => 9999,
            ;
        'wdqs-categories':
            port           => 9990,
            ;
    }
}
