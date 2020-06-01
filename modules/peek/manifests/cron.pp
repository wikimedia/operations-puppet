class peek::cron {

    cron { 'peek_monthly':
        ensure   => absent,
        command  => '. $HOME/.profile; /var/lib/peek/git/peek.py -c /etc/peek/config/base.conf,/etc/peek/config/monthly.conf -s 2>&1',
        user     => 'peek',
        monthday => 1,
    }

    cron { 'peek_weekly':
        ensure  => absent,
        command => '. $HOME/.profile; /var/lib/peek/git/peek.py -c /etc/peek/config/base.conf,/etc/peek/config/weekly.conf -s 2>&1',
        user    => 'peek',
        weekday => 1,
    }
}
