# SPDX-License-Identifier: Apache-2.0
#
# = define: prometheus::node_varnish_params
#
# Output varnish parameters for consumption by Prometheus' node_exporter
#
# = Parameters
#
# [*param_thread_pool_max*]
#   Maximum threads per pool.
#
# [*outfile*]
#   Path to write the consumable file.

define prometheus::node_varnish_params (
    Integer[1] $param_thread_pool_max,
    Pattern[/\.prom$/] $outfile,
    Wmflib::Ensure $ensure = 'present',
) {
    file { $outfile:
        ensure  => stdlib::ensure($ensure, 'file'),
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('prometheus/varnish_params.prom.erb'),
    }
}
