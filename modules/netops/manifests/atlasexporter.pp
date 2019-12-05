# == Class: netops::atlasexporter
#
# Sets up a Prometheus exporter for RIPE Atlas checks.
#
# === Parameters
#
# [*atlas_measurements*]
# a hash of datacenter => ipv4 and ipv6 measurement IDs,
# as used by monitoring.pp/ripeatlas.pp.

class netops::atlasexporter(
    Hash[String, Hash] $atlas_measurements,
    Stdlib::Port $exporter_port,
) {
    require_package('prometheus-atlas-exporter')

    $config_file = '/etc/prometheus-atlas-exporter.yaml'

    # For the exporter, we need to write out key=>value pairs of key 'id'
    # and value of the measurement ID.
    $measurement_ids = $atlas_measurements.reduce([]) |$acc, $elem| {
        concat($acc, [{'id' => $elem[1]['ipv4']},
                      {'id' => $elem[1]['ipv6']}])
    }

    file { $config_file:
        ensure  => 'file',
        content => to_yaml({'measurements' => $measurement_ids}),
        owner   => 'prometheus',
        notify  => Systemd::Service['prometheus-atlas-exporter'],
    }

    systemd::service { 'prometheus-atlas-exporter':
        ensure  => 'present',
        content => systemd_template('prometheus-atlas-exporter'),
        require => [ Package['prometheus-atlas-exporter'], File[$config_file] ],
        restart => true,
    }
}
