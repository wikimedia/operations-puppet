class peek::cron {

    cron { 'peek_monthly':
        command  => '/var/lib/peek/peek/peek.py -c /etc/peek/base.yml,/etc/peek/monthly.yml -s 2>&1',
        user     => 'peek',
        monthday => 1,
    }

    cron { 'peek_weekly':
        command => '/var/lib/peek/peek/peek.py -c /etc/peek/base.yml,/etc/peek/weekly.yml -s 2>&1',
        user    => 'peek',
        weekday => 1,
    }
}
