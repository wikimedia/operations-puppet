class varnish::monitoring::ganglia($varnish_instances=['']) {
    file { '/usr/lib/ganglia/python_modules/varnish.py':
        ensure => absent,
    }

    file { '/etc/ganglia/conf.d/varnish.pyconf':
        ensure => absent,
        notify => Service['ganglia-monitor'],
    }

    file { '/usr/local/sbin/check-gmond-restart':
        ensure => absent,
    }

    file { '/etc/cron.d/check-gmond-restart':
        ensure => absent,
    }
}
