# SPDX-License-Identifier: Apache-2.0
#
# = define: prometheus::node_varnish_params
#
# Output runtime varnish parameters for consumption by Prometheus' node_exporter
#
# = Parameters
#
# [*outfile*]
#   Path to write the consumable file.

define prometheus::node_varnish_params (
    Wmflib::Ensure $ensure = 'absent',
    Pattern[/\.prom$/] $outfile = '/var/lib/prometheus/node.d/varnish_params.prom',
) {
    file { '/usr/local/bin/prometheus-varnish-params':
        ensure => absent,
    }

    systemd::timer::job { 'prometheus_varnish_params':
        ensure      => $ensure,
        require     => File['/usr/local/bin/prometheus-varnish-params'],
        description => 'Collect select Varnish runtime parameters',
        user        => 'root',
        command     => "/usr/local/bin/prometheus-varnish-params ${outfile}",
        interval    => {'start' => 'OnCalendar', 'interval' => '*:0/10'},
    }
}
