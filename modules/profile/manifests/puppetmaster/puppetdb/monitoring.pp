# Class: profile::puppetmaster::puppetdb::monitoring
#
# Sets up Prometheus based monitoring (only jvm) for the PuppetDB JVM.
#
class profile::puppetmaster::puppetdb::monitoring(
    $prometheus_nodes        = hiera('prometheus_nodes'),
) {
    # Prometheus JMX agent for the Puppetdb's JVM
    $jmx_exporter_config_file = '/etc/puppetdb/jvm_prometheus_puppetdb_jmx_exporter.yaml'
    $prometheus_jmx_exporter_port = 9400
    $prometheus_java_opts = "-javaagent:/usr/share/java/prometheus/jmx_prometheus_javaagent.jar=${::ipaddress}:${prometheus_jmx_exporter_port}:${jmx_exporter_config_file}"
    profile::prometheus::jmx_exporter { "puppetdb_${::hostname}":
        hostname         => $::hostname,
        port             => $prometheus_jmx_exporter_port,
        prometheus_nodes => $prometheus_nodes,
        config_file      => $jmx_exporter_config_file,
        source           => 'puppet:///modules/profile/puppetmaster/puppetdb/jvm_prometheus_puppetdb_jmx_exporter.yaml',
    }
}