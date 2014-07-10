
class icinga::logrotate {
    file { '/etc/logrotate.d/icinga':
        ensure => present,
        source => 'puppet:///icinga/logrotate',
        mode   => '0444',
    }
}

