# SPDX-License-Identifier: Apache-2.0
class prometheus::node_kernel_messages (
    Wmflib::Ensure $ensure = 'present',
) {
    $script = '/usr/local/bin/prometheus-node-kernel-messages'
    file { $script:
        ensure => $ensure,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-node-kernel-messages.sh',
    }

    $ignore_regex_file = '/etc/prometheus-node-kernel-messages-ignore-regex.txt'
    file { $ignore_regex_file:
        ensure => $ensure,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/prometheus-node-kernel-messages-ignore-regex.txt',
    }

    systemd::timer::job { 'prometheus-node-kernel-messages':
        ensure      => $ensure,
        user        => 'root',
        description => 'Generate prometheus stats about kernel messages',
        command     => $script,
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => 'minutely',
        },
        require     => [
          File[$script],
          Class['prometheus::node_exporter'],
          Package['jq'],
        ],
    }
}
