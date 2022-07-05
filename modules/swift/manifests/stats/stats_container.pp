# SPDX-License-Identifier: Apache-2.0
define swift::stats::stats_container (
    $account_name,
    $container_set,
    $statsd_prefix,
    Wmflib::Ensure $ensure = present,
    $statsd_host = 'localhost',
    $statsd_port = 9125,
) {
    $account_file = "/etc/swift/account_${account_name}.env"

    systemd::timer::job { "swift-container-stats_${title}":
        ensure          => $ensure,
        description     => 'Regular jobs to report container statistics',
        user            => 'root',
        command         => "/usr/local/bin/swift-container-stats-timer.sh ${account_file} ${statsd_prefix} ${statsd_host} ${statsd_port} ${container_set}",
        logging_enabled => false,
        interval        => {'start' => 'OnCalendar', 'interval' => '*-*-* *:0/10:00'},
        require         => [
            File[$account_file],
            File['/usr/local/bin/swift-container-stats']
        ],
    }
}
