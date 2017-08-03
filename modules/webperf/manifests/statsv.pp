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

    scap::target { 'statsv/statsv':
        service_name => 'statsv',
        deploy_user  => 'deploy-service',
    }

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
