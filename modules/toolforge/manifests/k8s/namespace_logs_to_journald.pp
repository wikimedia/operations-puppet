# SPDX-License-Identifier: Apache-2.0
# This schedules a script on all toolforge k8s nodes to send logs from specified namespaces to journald
class toolforge::k8s::namespace_logs_to_journald() {

    file { '/usr/local/bin/namespace_logs_to_journald.sh':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/toolforge/k8s/namespace_logs_to_journald.sh',
    }

    systemd::timer::job { 'namespace-logs-to-journald':
        ensure          => present,
        logging_enabled => false,
        user            => 'root',
        description     => 'Send logs from specified namespaces to journald',
        command         => '/usr/local/bin/namespace_logs_to_journald.sh maintain-harbor',
        interval        => {
        'start'    => 'OnCalendar',
        'interval' => '*-*-* *:0/30:00',# run every 30mins (at :00 and :30 past the hour)
        },
        require         => File['/usr/local/bin/namespace_logs_to_journald.sh'],}
}
