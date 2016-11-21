# == Class: webperf::statsv
#
# Sets up StatsV, a Web request -> Kafka -> StatsD bridge.
#
class webperf::statsv {
    include ::webperf

    require_package('python-kafka')

    # These are rendered in statsv.service
    $kafka_config  = kafka_config('analytics')
    $kafka_brokers = $kafka_config['brokers']['string']
    $statsd        = hiera('statsd')

    package { 'statsv':
        ensure   => present,
        provider => 'trebuchet',
    }

    file { '/lib/systemd/system/statsv.service':
        ensure  => 'present',
        content => template('webperf/statsv.service.erb'),
        require => Package['statsv'],
    }

    service { 'statsv':
        ensure   => 'running',
        provider => 'systemd',
        subscribe => File['/lib/systemd/system/statsv.service'],
    }
}
