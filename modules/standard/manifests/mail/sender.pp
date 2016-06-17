class standard::mail::sender {
    class { 'exim4':
        queuerunner => 'queueonly',
        config      => template("mail/exim4.minimal.${::realm}.erb"),
    }

    # Perform a daily restart on Monday to Friday to pick up updated
    # versions in linked-in libraries etc.
    cron { 'exim4_daily_restart':
        ensure  => present,
        command => '/usr/sbin/service exim4 restart',
        user    => 'root',
        hour    => fqdn_rand(23, 'exim4_daily_restart'),
        minute  => fqdn_rand(59, 'exim4_daily_restart'),
        weekday => '1-5',
    }
}
