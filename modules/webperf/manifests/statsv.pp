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
    systemd::service { 'statsv':
        content => template('webperf/statsv.service.erb'),
        restart => true,
    }
}
