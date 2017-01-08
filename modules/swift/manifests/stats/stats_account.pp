define swift::stats::stats_account (
    $accounts,
    $statsd_prefix,
    $statsd_host,
    $credentials,
) {
    $account_info = $accounts[$name]
    $auth_url     = $account_info[auth]
    $user         = $account_info[user]
    $key          = $credentials[$name]
    $account_name = $account_info[account_name]
    $stats_enabled = $account_info[stats_enabled]

    $account_file = "/etc/swift/account_${account_name}.env"
    $account_statsd_prefix = "${statsd_prefix}.${account_name}"

    if $stats_enabled != 'no' {
        file { $account_file:
            owner   => 'root',
            group   => 'root',
            mode    => '0440',
            content => "export ST_AUTH=${auth_url}/auth/v1.0\nexport ST_USER=${user}\nexport ST_KEY=${key}\n",
        }

        cron { "swift-account-stats_${user}":
            ensure  => present,
            command => ". ${account_file} && /usr/local/bin/swift-account-stats --prefix ${account_statsd_prefix} --statsd-host ${statsd_host} 1>/dev/null",
            user    => 'root',
            hour    => '*',
            minute  => '*',
            require => [File[$account_file],
                        File['/usr/local/bin/swift-account-stats']],
        }
    }
}
