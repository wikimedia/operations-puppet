# SPDX-License-Identifier: Apache-2.0
# == Class: webperf::statsv
#
# Sets up StatsV, a Web request -> Kafka -> StatsD bridge.
#
# [*kafka_brokers*]
#   string of comma separated Kafka bootstrap brokers
#
# [*kafka_security_protocol*]
#   one of "PLAINTEXT", "SSL", "SASL", "SASL_SSL"
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
    String                     $kafka_brokers,
    Optional[String]           $kafka_security_protocol = 'PLAINTEXT',
    Optional[String]           $kafka_api_version       = undef,
    String                     $topics                  = 'statsv',
    Stdlib::Fqdn               $statsd_host             = 'localhost',
    Integer                    $statsd_port             = 8125,
    Optional[Stdlib::Unixpath] $kafka_ssl_cafile        = undef,
) {
    include ::webperf

    ensure_packages(['python3-kafka'])

    scap::target { 'statsv/statsv':
        service_name => 'statsv',
        deploy_user  => 'deploy-service',
    }

    # Uses $kafka_brokers, $kafka_security_protocol, $kafka_ssl_cafile, and $statsd
    systemd::unit { 'statsv':
        ensure  => present,
        content => template('webperf/statsv.service.erb'),
        restart => true,
    }

    service { 'statsv':
        ensure   => running,
        provider => systemd,
    }

    nrpe::monitor_service { 'statsv':
        description  => 'statsv process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1: -C python3 -a statsv',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Graphite#statsv',
    }
}
