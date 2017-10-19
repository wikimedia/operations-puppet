# == Define profile::prometheus::jmx_exporter
#
# Renders a Prometheus JMX Exporter config file, declares
# a prometheus::jmx_exporter_instance so that the prometheus server
# will be configured to pull from this exporter instance,
# and installs ferm rules to allow it to do so.
# The hostname:port combination, derived from the define's parameters, will
# be used as Prometheus target (so metrics will be associated to it). This trick
# should allow the configuration of multiple Prometheus targets on the same
# machine, for use cases like Cassandra (multiple JVM instances with different
# domains on the same host) or Kafka (Kafka/MirrorMaker JVMs on the same host).
#
define profile::prometheus::jmx_exporter (
    $hostname,
    $port,
    $prometheus_nodes,
    $config_file,
    $content = undef,
    $source  = undef,
) {
    if $source == undef and $content == undef {
        fail('you must provide either "source" or "content"')
    }

    if $source != undef and $content != undef  {
        fail('"source" and "content" are mutually exclusive')
    }

    require_package('prometheus-jmx-exporter')

    # Create the Prometheus JMX Exporter configuration
    file { $config_file:
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => $content,
        source  => $source,
        # If the source is using a symlink, copy the link target, not the symlink.
        links   => 'follow',
    }

    # Allow automatic generation of config on the Prometheus master.
    prometheus::jmx_exporter_instance { $title:
        hostname => $hostname,
        port     => $port,
    }

    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')
    ferm::service { "${title}_jmx_exporter":
        proto  => 'tcp',
        port   => $port,
        srange => "@resolve((${prometheus_nodes_ferm}))",
    }
}
