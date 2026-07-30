# SPDX-License-Identifier: Apache-2.0
# = Define: prometheus::node_ferm_mss
#
# Periodically export MSS values of realserver IPs via node-exporter
# textfile collector.
define prometheus::node_nftables_mss (
    Wmflib::Ensure $ensure,
    Pattern[/\.prom$/] $outfile = '/var/lib/prometheus/node.d/nftables-mss.prom',
) {
    ensure_packages(['python3-prometheus-client'])

    file { '/usr/local/bin/prometheus-nftables-mss':
        ensure => stdlib::ensure($ensure, 'file'),
        mode   => '0555',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-nftables-mss.py',
    }

    # Collect every minute
    systemd::timer::job { 'prometheus_nftables_mss':
        ensure      => $ensure,
        description => 'Regular job to collect MSS values of nftables-based hosts',
        user        => 'root',
        command     => "/usr/local/bin/prometheus-nftables-mss -o ${outfile}",
        interval    => {'start' => 'OnCalendar', 'interval' => 'minutely'},
    }
}
