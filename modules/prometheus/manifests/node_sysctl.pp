# SPDX-License-Identifier: Apache-2.0
#
# = Class: prometheus::node_sysctl
#
# Periodically export select sysctl keys/values to node-exporter
# textfile collector.
class prometheus::node_sysctl (
    Wmflib::Ensure $ensure = 'present',
    Pattern[/\.prom$/] $outfile = '/var/lib/prometheus/node.d/sysctl.prom',
) {
    file { '/usr/local/bin/prometheus-sysctl':
        ensure => $ensure,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-sysctl',
    }

    systemd::timer::job { 'prometheus_sysctl':
        ensure      => $ensure,
        require     => File['/usr/local/bin/prometheus-sysctl'],
        description => 'Regular job to collect select sysctl keys/values',
        user        => 'root',
        command     => "/usr/local/bin/prometheus-sysctl ${outfile}",
        interval    => {'start' => 'OnCalendar', 'interval' => '*:0/5'},
    }
}
