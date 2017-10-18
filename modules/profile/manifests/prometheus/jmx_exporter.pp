# == Define profile::prometheus::jmx_exporter
# Renders a Prometheus JMX Exporter config file, declares
# a prometheus::jmx_exporter_instance so that the prometheus server
# will be configured to pull from this exporter instance,
# and installs ferm rules to allow it to do so.
#
define profile::prometheus::jmx_exporter (
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
        address => $::ipaddress,
        port    => $port,
    }

    $prometheus_nodes_ferm = join($prometheus_nodes, ' ')
    ferm::service { "${title}_jmx_exporter":
        proto  => 'tcp',
        port   => $port,
        srange => "@resolve((${prometheus_nodes_ferm}))",
    }
}
