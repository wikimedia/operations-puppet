# SPDX-License-Identifier: Apache-2.0
#
# = Class: prometheus::node_ats_config
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

define prometheus::node_ats_config (
    Wmflib::Ensure $ensure = 'present',
    Pattern[/\.prom$/] $outfile = '/var/lib/prometheus/node.d/ats_config.prom',
) {
    $exec = '/usr/local/bin/prometheus-ats-config'
    file { $exec:
        ensure => absent,
    }

    # Collect every 10 minutes
    systemd::timer::job { 'prometheus-ats-config':
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

