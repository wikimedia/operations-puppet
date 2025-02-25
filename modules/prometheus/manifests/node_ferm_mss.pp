# SPDX-License-Identifier: Apache-2.0
# = Define: prometheus::node_ferm_mss
#
# Periodically export MSS values of realserver IPs via node-exporter
# textfile collector.
define prometheus::node_ferm_mss (
    Wmflib::Ensure $ensure,
    Array[String] $clamped_ipport,
    Pattern[/\.prom$/] $outfile = '/var/lib/prometheus/node.d/ferm-mss.prom',
) {
    ensure_packages(['python3-prometheus-client'])

    file { '/usr/local/bin/prometheus-ferm-mss':
        ensure => stdlib::ensure($ensure, 'file'),
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-ferm-mss.py',
    }

    $endpoints = $clamped_ipport.join(' -e ')
    # Collect every minute
    systemd::timer::job { 'prometheus_ferm_mss':
        ensure      => $ensure,
        description => 'Regular job to collect MSS values of ferm-based hosts',
        user        => 'root',
        command     => "/usr/local/bin/prometheus-ferm-mss -o ${outfile} -e ${endpoints}",
        interval    => {'start' => 'OnCalendar', 'interval' => 'minutely'},
    }
}
