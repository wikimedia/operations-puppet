# SPDX-License-Identifier: Apache-2.0
class prometheus::node_kernel_messages () {
    $script = '/usr/local/bin/prometheus-node-kernel-messages'
    $dir = '/etc/prometheus'
    $ignore_regex_file = "${dir}/kernel-messages-ignore-regex.txt"

    file { [$script, $ignore_regex_file]:
        ensure  => absent,
    }

    systemd::timer::job { 'prometheus-node-kernel-messages':
        ensure      => absent,
        user        => 'root',
        description => 'Generate prometheus stats about kernel messages',
        command     => $script,
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => 'minutely',
        },
    }
}
