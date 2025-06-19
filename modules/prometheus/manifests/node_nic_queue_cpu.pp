# SPDX-License-Identifier: Apache-2.0
# = Define: prometheus::node_nic_queue_cpu
#
# Periodically export CPUs assigned to handle NIC queues via node-exporter
# textfile collector.
define prometheus::node_nic_queue_cpu (
    Wmflib::Ensure $ensure,
    String $interface,
    Pattern[/\.prom$/] $outfile = '/var/lib/prometheus/node.d/nic-queue-cpu.prom',
) {
    ensure_packages(['python3-prometheus-client'])

    if !File['/usr/local/bin/prometheus-nic-queue-cpu'] {
        file { '/usr/local/bin/prometheus-nic-queue-cpu':
            ensure => stdlib::ensure($ensure, 'file'),
            mode   => '0555',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-nic-queue-cpu.py',
        }
    }

    # Collect every hour
    systemd::timer::job { "prometheus_nic_queue_cpu_${interface}":
        ensure      => $ensure,
        description => "Regular job to collect CPUs assigned to handle ${interface} queues",
        user        => 'root',
        command     => "/usr/local/bin/prometheus-nic-queue-cpu -o ${outfile} -i ${interface}",
        interval    => {'start' => 'OnCalendar', 'interval' => 'hourly'},
    }
}
