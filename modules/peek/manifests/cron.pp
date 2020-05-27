class peek::cron {

    cron { 'peek_monthly':
        command  => '/var/lib/peek/git/peek.py -c /etc/peek/config/base.yml,/etc/peek/config/monthly.yml -s 2>&1',
        user     => 'peek',
        monthday => 1,
    }

    cron { 'peek_weekly':
        command => '/var/lib/peek/git/peek.py -c /etc/peek/config/base.yml,/etc/peek/config/weekly.yml -s 2>&1',
        user    => 'peek',
        weekday => 1,
    }
}
