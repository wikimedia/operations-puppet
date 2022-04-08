define swift::stats::stats_account (
    $accounts,
    $statsd_prefix,
    $credentials,
    Wmflib::Ensure $ensure = present,
    $statsd_host = 'statsd.eqiad.wmnet',
    $statsd_port = 8125,
) {
    $account_info  = $accounts[$name]
    $auth_url      = $account_info[auth]
    $user          = $account_info[user]
    $key           = $credentials[$name]
    $account_name  = $account_info[account_name]
    $stats_enabled = $account_info[stats_enabled]

    $account_file = "/etc/swift/account_${account_name}.env"
    $account_statsd_prefix = "${statsd_prefix}.${account_name}"

    if $stats_enabled != 'no' {
        file { $account_file:
            ensure  => $ensure,
            owner   => 'root',
            group   => 'root',
            mode    => '0440',
            content => "export ST_AUTH=${auth_url}/auth/v1.0\nexport ST_USER=${user}\nexport ST_KEY=${key}\n"
        }

        systemd::timer::job { "swift-account-stats_${user}":
            ensure          => $ensure,
            description     => 'Regular jobs to report swift account statistics',
            command         => "/usr/local/bin/swift-account-stats-timer.sh ${account_file} ${account_statsd_prefix} ${statsd_host} ${statsd_port}",
            user            => 'root',
            logging_enabled => true,
            interval        => {'start' => 'OnCalendar', 'interval' => 'minutely'},
            require         => [
                File[$account_file],
                File['/usr/local/bin/swift-account-stats'],
                File['/usr/local/bin/swift-account-stats-timer.sh']
            ],
        }

        cron { "swift-account-stats_${user}":
            ensure => absent,
        }
    }
}
