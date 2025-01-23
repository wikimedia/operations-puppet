# SPDX-License-Identifier: Apache-2.0
class prometheus::node_kernel_messages (
    Wmflib::Ensure $ensure = 'present',
) {
    #TODO: remove this after the old files have been cleaned up
    $old_script = '/usr/local/bin/prometheus-node-kernel-panic'
    file { $old_script:
      ensure => 'absent',
    }
    #TODO: remove this after the old files have been cleaned up
    systemd::timer::job { 'prometheus-node-kernel-panic':
        ensure      => 'absent',
        user        => 'root',
        description => 'Generate prometheus stats about kernel messages',
        command     => $old_script,
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => 'minutely',
        },
    }

    $script = '/usr/local/bin/prometheus-node-kernel-messages'
    file { $script:
        ensure => $ensure,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/prometheus/usr/local/bin/prometheus-node-kernel-messages.sh',
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
