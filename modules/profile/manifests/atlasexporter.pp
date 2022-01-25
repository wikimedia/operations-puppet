# == Class: profile::atlasexporter
#
# Sets up a Prometheus exporter for RIPE Atlas checks.
#
class profile::atlasexporter(
    Hash[String, Hash] $atlas_measurements = lookup('ripeatlas_measurements'),
    $exporter_port    = lookup('profile::atlasexporter::exporter_port'),
) {
    class { 'netops::atlasexporter':
        atlas_measurements => $atlas_measurements,
        exporter_port      => $exporter_port,
    }
    # Generate a textfile exporter that provides atlas_measurement_label,
    # with metadata about each measurement ID, suitable for joining against
    # other metrics (similar to node_hwmon_sensor_label).
    file {'/var/lib/prometheus/node.d/atlas_metadata.prom':
        ensure  => 'file',
        content => template('profile/atlasexporter/atlas_metadata.prom.erb'),
    }
}
