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
    require ::profile::prometheus::blazegraph_exporter

    $username = 'blazegraph'
    $prometheus_agent_path = '/usr/share/java/prometheus/jmx_prometheus_javaagent.jar'
    $prometheus_agent_config = '/etc/wdqs/wdqs-blazegraph-prometheus-jmx.yaml'
    $default_extra_jvm_opts = [
        '-XX:+UseNUMA',
        '-XX:+UnlockExperimentalVMOptions',
        '-XX:G1NewSizePercent=20',
        '-XX:+ParallelRefProcEnabled',
    ]

    $prometheus_agent_port_wdqs = 9102
    profile::prometheus::jmx_exporter {
        default:
            hostname         => $::hostname,
            prometheus_nodes => $prometheus_nodes,
            config_file      => $prometheus_agent_config,
            source           => 'puppet:///modules/profile/wdqs/wdqs-blazegraph-prometheus-jmx.yaml',
            ;
        'wdqs_blazegraph':
            port   => $prometheus_agent_port_wdqs,
            before => Service['wdqs-blazegraph'],
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
            extra_jvm_opts   => $default_extra_jvm_opts + $extra_jvm_opts +  "-javaagent:${prometheus_agent_path}=${prometheus_agent_port_wdqs}:${prometheus_agent_config}"
    }

    # No monitoring for lag for secondary servers
    class { 'wdqs::monitor::blazegraph':
        port           => 9999,
        username       => $username,
        contact_groups => $contact_groups,
        lag_warning    => $lag_warning,
        lag_critical   => $lag_critical,
    }

}
