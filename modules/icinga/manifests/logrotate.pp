# = Class: icinga::logrotate
# 
# Sets up log rotation for icinga logs
class icinga::logrotate {
    file { '/etc/logrotate.d/icinga':
        ensure => present,
        source => 'puppet:///modules/icinga/logrotate.conf',
        mode   => '0444',
    }
}
