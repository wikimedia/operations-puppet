# == Class: webperf::statsv
#
# Sets up StatsV, a Web request -> Kafka -> StatsD bridge.
#
# [*kafka_brokers*]
#   string of comma separated Kafka bootstrap brokers
#
# [*kafka_api_version*]
#   Only set this if you need to specify the api version.  This should not be needed
#   Beyond kafka 0.9.
#
# [*topics*]
#   Comma separated list of topics from which statsv should consume. Default: statsv
#
# [*statsd_host*]
#   host name of statsd instance.  Default: localhost
#
# [*statsd_port*]
#   port of statsd instance.  Default: 8125
#
class webperf::statsv(
    String $kafka_brokers,
    Optional[String] $kafka_api_version = undef,
    String $topics            = 'statsv',
    Stdlib::Fqdn $statsd_host = 'localhost',
    Integer $statsd_port      = 8125,
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
