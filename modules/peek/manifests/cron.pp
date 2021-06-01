class peek::cron {

    cron { 'peek_monthly':
        ensure      => absent,
        command     => '. $HOME/.profile; /var/lib/peek/git/peek.py -c /etc/peek/config/base.conf,/etc/peek/config/monthly.conf -s > /dev/null',
        environment => 'MAILTO=security-team@wikimedia.org',
        user        => 'peek',
        minute      => 0,
        hour        => 0,
        monthday    => 1,
    }

    cron { 'peek_weekly':
        ensure      => absent,
        command     => '. $HOME/.profile; /var/lib/peek/git/peek.py -c /etc/peek/config/base.conf,/etc/peek/config/weekly.conf -s > /dev/null',
        environment => 'MAILTO=security-team@wikimedia.org',
        user        => 'peek',
        minute      => 0,
        hour        => 0,
        weekday     => 1,
    }
}
