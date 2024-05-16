# SPDX-License-Identifier: Apache-2.0
# = Define: prometheus::node_lvs_realserver_ipip
#
# Periodically export MSS values of realserver IPs via node-exporter
# textfile collector.
define prometheus::node_lvs_realserver_mss (
    Wmflib::Ensure $ensure,
    Array[String] $clamped_ipport,
    Pattern[/\.prom$/] $outfile = '/var/lib/prometheus/node.d/lvs-realserver-mss.prom',
) {
    ensure_packages(['python3-prometheus-client'])

    file { '/usr/local/bin/prometheus-lvs-realserver-mss':
        ensure => stdlib::ensure($ensure, 'file'),
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-lvs-realserver-mss.py',
    }

    $endpoints = $clamped_ipport.join(' -e ')
    # Collect every 5 minutes
    systemd::timer::job { 'prometheus_lvs_realserver_mss':
        ensure      => $ensure,
        description => 'Regular job to collect MSS values of realserver endpoints',
        user        => 'root',
        command     => "/usr/local/bin/prometheus-lvs-realserver-mss -o ${outfile} -e ${endpoints}",
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* *:0/5:0'},
    }
}
