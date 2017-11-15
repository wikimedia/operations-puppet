# == Class: webperf::statsv
#
# Sets up StatsV, a Web request -> Kafka -> StatsD bridge.
#
# [*kafka_brokers*]
#   string of comma separated Kafka bootstrap brokers
#
# [*topics*]
#   Comma separated list of topics from which statsv should consume. Default statsv
#
# [*statsd*]
#   host:port of statsd instance.  Default: localhost:8125
#
class webperf::statsv(
    $kafka_brokers,
    $topics = 'statsv',
    $statsd = 'localhost:8125',
) {
    include ::webperf

    require_package('python-kafka')

    scap::target { 'statsv/statsv':
        service_name => 'statsv',
        deploy_user  => 'deploy-service',
    }

    # Uses $kafka_brokers and $statsd
    file { '/lib/systemd/system/statsv.service':
        ensure  => 'present',
        content => template('webperf/statsv.service.erb'),
        require => Package['statsv/statsv'],
    }

    service { 'statsv':
        ensure    => 'running',
        provider  => 'systemd',
        subscribe => File['/lib/systemd/system/statsv.service'],
    }

    nrpe::monitor_service { 'statsv':
        description  => 'statsv process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1: -C python -a statsv',
    }
}
