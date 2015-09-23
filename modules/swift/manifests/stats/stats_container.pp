define swift::stats::stats_container (
    $account_name,
    $statsd_prefix,
    $statsd_host,
) {
    $account_file = "/etc/swift/account_${account_name}.env"
    $container_statsd_prefix = "${statsd_prefix}.${account_name}"

    cron { "swift-container-stats_${account_name}":
        ensure  => present,
        command => ". ${account_file} && /usr/local/bin/swift-container-stats --prefix ${container_statsd_prefix} --statsd-host ${statsd_host} --ignore-unknown 1>/dev/null",
        user    => 'root',
        hour    => '*',
        minute  => '*',
        require => [File[$account_file],
                    File['/usr/local/bin/swift-container-stats']],
    }
}
