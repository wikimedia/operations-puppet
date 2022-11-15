# SPDX-License-Identifier: Apache-2.0
#
# = define: prometheus::node_trafficserver_config
#
# Output the hiera configurations for ATS for consumption by Prometheus' node_exporter.
#
# = Parameters
#
# [*config_max_conns*]
#   ATS max_connections_in value to represent to Prometheus.
#
# [*config_max_reqs*]
#   ATS max_requests_in value to represent to Prometheus.
#
# [*outfile*]
#   Path to write the consumable file.

define prometheus::node_trafficserver_config (
    Integer[0] $config_max_conns,
    Integer[0] $config_max_reqs,
    Pattern[/\.prom$/] $outfile,
    Wmflib::Ensure $ensure = 'present',
) {
    file { $outfile:
        ensure  => stdlib::ensure($ensure, 'file'),
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('prometheus/trafficserver_config.prom.erb'),
    }

    # Old collection script/timer
    file { '/usr/local/bin/prometheus-trafficserver-config': ensure => 'absent' }
    systemd::timer::job { 'prometheus-trafficserver-config':
        ensure          => 'absent',
        description     => 'Export select ATS configuration paramaters to node_exporter',
        command         => '/bin/true',
        user            => 'root',
        logging_enabled => false,
        interval        => {
            'start'    => 'OnUnitInactiveSec',
            'interval' => '10m',
        },
    }
}
