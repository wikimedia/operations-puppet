# SPDX-License-Identifier: Apache-2.0
class prometheus::node_toolforge_prometheus_k8s_nfs_stuck_exporter (
    Wmflib::Ensure   $ensure      = 'present',
) {
    $script = '/usr/local/bin/processes-stuck-on-nfs'
    prometheus::node_textfile {'processes-stuck-on-nfs':
        ensure     => $ensure,
        interval   => 'minutely',
        run_cmd    => $script,
        filesource => 'puppet:///modules/prometheus/usr/local/bin/prometheus_k8s_nfs_stuck_exporter.sh',
    }
}
