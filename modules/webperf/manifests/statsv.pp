# == Class: webperf::statsv
#
# Sets up StatsV, a Web request -> Kafka -> StatsD bridge.
#
class webperf::statsv {
    include ::webperf

    package { 'statsv':
        ensure   => present,
        provider => 'trebuchet',
    }

    file { '/etc/init/statsv.conf':
        ensure  => present,
        source  => 'puppet:///modules/webperf/statsv.conf',
        require => Package['statsv'],
        notify  => Service['statsv'],
    }

    service { 'statsv':
        ensure   => running,
        provider => 'upstart',
    }
}
