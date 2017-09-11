class prometheus {
    file { '/etc/prometheus-apache':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/srv/prometheus':
        ensure => directory,
    }

    logrotate::conf { 'prometheus':
        ensure => present,
        source => 'puppet:///modules/prometheus/prometheus.logrotate.conf',
    }

    rsyslog::conf { 'prometheus':
        source   => 'puppet:///modules/prometheus/prometheus.rsyslog.conf',
        priority => 40,
    }
}
