# vim:sw=4:ts=4:et:

# Ganglia monitoring
class protoproxy::ganglia {

    file { '/usr/lib/ganglia/python_modules/apache_status.py':
        source => 'puppet:///files/ganglia/plugins/apache_status.py',
        notify => Service['gmond'];
    }
    file { '/etc/ganglia/conf.d/apache_status.pyconf':
        source => 'puppet:///files/ganglia/plugins/apache_status.pyconf',
        notify => Service['gmond'];
    }

    # Dummy site to provide a status to Ganglia
    nginx::site { 'localhost':
        content => template('protoproxy/localhost.erb'),
    }

}
