
class icinga::monitor::logrotate {
    file { '/etc/logrotate.d/icinga':
        ensure => present,
        source => 'puppet:///files/logrotate/icinga',
        mode   => '0444',
    }
}

