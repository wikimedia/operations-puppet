# SPDX-License-Identifier: Apache-2.0
#
# = define: prometheus::node_trafficserver_config
#
# Periodically parse the ATS configuration file text and export e.g. the max
# number of connnections set via a node_exporter textfile collector.
#
# = Parameters
#
# [*records config*]
#   Path to read in ATS' records configuration
#
# [*outfile*]
#   Path to write the finished textfile-exporter-format file.

define prometheus::node_trafficserver_config (
    Wmflib::Ensure $ensure = 'present',
    Pattern[/\.prom$/] $outfile = '/var/lib/prometheus/node.d/trafficserver_config.prom',
) {
    $exec = '/usr/local/bin/prometheus-trafficserver-config'
    file { $exec:
        ensure => $ensure,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-trafficserver-config.sh',
    }

    # Collect every 10 minutes
    systemd::timer::job { 'prometheus-trafficserver-config':
        ensure          => $ensure,
        description     => 'Export select ATS configuration paramaters to node_exporter',
        command         => $exec,
        user            => 'root',
        logging_enabled => false,
        require         => [File[$exec]],
        interval        => {
            'start'    => 'OnUnitInactiveSec',
            'interval' => '10m',
        },
    }
}
