# SPDX-License-Identifier: Apache-2.0
class prometheus::node_kernel_panic (
    Wmflib::Ensure $ensure  = 'present',
) {
    $script = '/usr/local/bin/prometheus-node-kernel-panic'
    file { $script:
        ensure => $ensure,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-node-kernel-panic.sh',
    }

    systemd::timer::job { 'prometheus-node-kernel-panic':
        ensure      => $ensure,
        user        => 'root',
        description => 'Generate kernel panic stats for the prometheus node exporter',
        command     => $script,
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => 'minutely',
        },
        require     => [File[$script], Class['prometheus::node_exporter'],]
    }
}
