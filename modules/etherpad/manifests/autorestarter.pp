# = class: etherpad::autorestarter
#
# Sets up a monit instance to restart etherpad if it is down
# This is a temporary (HAHA!) Hack to prevent people from having
# to manually ping an operations person to restart etherpad
class etherpad::autorestarter {
    package { 'monit':
        ensure => present,
    }

    service { 'monit':
        ensure  => running,
        require => Package['monit'],
    }

    file { '/etc/monit/conf.d/etherpad':
        source => 'puppet:///modules/etherpad/monitrc',
        notify => Service['monit'],
    }
}
