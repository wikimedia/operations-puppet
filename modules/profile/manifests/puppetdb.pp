class profile::puppetdb(
    $master = hiera('profile::puppetdb::master'),
    $puppetmasters = hiera('puppetmaster::servers'),
    $jvm_opts = hiera('profile::puppetdb::jvm_opts', '-Xmx4G'),
    $prometheus_nodes = hiera('prometheus_nodes'),
    $puppetdb_major_version = hiera('puppetdb_major_version', undef),
    $puppetdb_package_variant = hiera('puppetdb_package_variant', undef),
) {

    # Prometheus JMX agent for the Puppetdb's JVM
    $jmx_exporter_config_file = '/etc/puppetdb/jvm_prometheus_puppetdb_jmx_exporter.yaml'
    $prometheus_jmx_exporter_port = 9400
    $prometheus_java_opts = "-javaagent:/usr/share/java/prometheus/jmx_prometheus_javaagent.jar=${::ipaddress}:${prometheus_jmx_exporter_port}:${jmx_exporter_config_file}"

    # The JVM heap size has been raised to 6G for T170740
    class { '::puppetmaster::puppetdb':
        master                   => $master,
        jvm_opts                 => "${jvm_opts} ${prometheus_java_opts}",
        puppetdb_major_version   => $puppetdb_major_version,
        puppetdb_package_variant => $puppetdb_package_variant,
    }

    # Export JMX metrics to prometheus
    profile::prometheus::jmx_exporter { "puppetdb_${::hostname}":
        hostname         => $::hostname,
        port             => $prometheus_jmx_exporter_port,
        prometheus_nodes => $prometheus_nodes,
        config_file      => $jmx_exporter_config_file,
        source           => 'puppet:///modules/profile/puppetmaster/puppetdb/jvm_prometheus_puppetdb_jmx_exporter.yaml',
    }

    # Firewall rules

    # Only the TLS-terminating nginx proxy will be exposed
    $puppetmasters_ferm = inline_template('<%= @puppetmasters.values.flatten(1).map { |p| p[\'worker\'] }.sort.join(\' \')%>')

    ferm::service { 'puppetdb':
        proto   => 'tcp',
        port    => 443,
        notrack => true,
        srange  => "@resolve((${puppetmasters_ferm}))",
    }

    ferm::service { 'puppetdb-cumin':
        proto  => 'tcp',
        port   => 443,
        srange => '$CUMIN_MASTERS',
    }

}
