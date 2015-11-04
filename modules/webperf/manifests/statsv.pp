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

    file { '/lib/systemd/system/statsv.service':
        ensure  => present,
        source  => 'puppet:///modules/webperf/statsv.service',
        require => Package['statsv'],
        notify  => Service['statsv'],
    }

    service { 'statsv':
        ensure   => running,
        provider => 'systemd',
    }
}
