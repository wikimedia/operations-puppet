# == Class: profile::atlasexporter
#
# Sets up a Prometheus exporter for RIPE Atlas checks.
#
class profile::atlasexporter(
    Hash[String, Hash] $atlas_measurements = lookup('ripeatlas_measurements'),
    $prometheus_nodes = lookup('prometheus_nodes'),
    $exporter_port    = lookup('profile::atlasexporter::exporter_port'),
) {
    class { 'netops::atlasexporter':
        atlas_measurements => $atlas_measurements,
        exporter_port      => $exporter_port,
    }
    $prometheus_nodes_str = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_nodes_str})) @resolve((${prometheus_nodes_str}), AAAA))"
    ferm::service { 'prometheus-atlas-exporter':
        proto  => 'tcp',
        port   => $exporter_port,
        srange => $ferm_srange,
    }

    # Generate a textfile exporter that provides atlas_measurement_label,
    # with metadata about each measurement ID, suitable for joining against
    # other metrics (similar to node_hwmon_sensor_label).
    file {'/var/lib/prometheus/node.d/atlas_metadata.prom':
        ensure  => 'file',
        content => template('profile/atlasexporter/atlas_metadata.prom.erb'),
    }
}
