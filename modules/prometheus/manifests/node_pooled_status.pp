# SPDX-License-Identifier: Apache-2.0
# = Define: prometheus::node_pooled_status
#
# Periodically export cp* hosts' depooled/pooled states via node-exporter
# textfile collector.
define prometheus::node_pooled_status (
    Wmflib::Ensure $ensure,
) {

    file { '/usr/local/bin/prometheus-pool-status-exporter':
        ensure => stdlib::ensure($ensure, 'file'),
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-pool-status-exporter.py',
    }

    systemd::timer::job { 'prometheus_pooled_hosts':
        ensure      => $ensure,
        description => 'Regular job to collect pooled status of hosts',
        user        => 'prometheus',
        command     => '/usr/local/bin/prometheus-pool-status-exporter -o /var/lib/prometheus/node.s/node_pooled_status.prom',
        interval    => {'start' => 'OnCalendar', 'interval' => '*:0/15'}, # every 15 minutes
    }
}
