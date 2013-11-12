# vim:sw=4:ts=4:et:

# Ganglia monitoring
class protoproxy::ganglia {

    include nginx::package

    file { '/usr/lib/ganglia/python_modules/apache_status.py':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///files/ganglia/plugins/apache_status.py',
        notify => Service['gmond'];
    }
    file { '/etc/ganglia/conf.d/apache_status.pyconf':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///files/ganglia/plugins/apache_status.pyconf',
        notify => Service['gmond'];
    }

    # Dummy site to provide a status to Ganglia
    nginx { 'localhost.conf':
        install => true,
        enable  => true,
        require => Package['nginx'],
    }

}
