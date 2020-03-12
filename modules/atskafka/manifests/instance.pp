# == Define: atskafka::instance
#
# This module configures atskafka, a system to stream ATS request logs to
# Kafka. See https://github.com/wikimedia/atskafka
#
# === Parameters
#
# [*brokers*]
#   Array of Kafka broker host:ports.
#
# [*stats_dir*]
#   The directory where rdkafka metrics are to be stored.
#
# [*stats_interval_ms*]
#   Flush rdkafka statistics every stats_interval_ms.
#
# [*topic*]
#   Kafka topic to which all logs must be written.
#
# [*numeric_fields*]
#   Array of fields to be considered as numeric. All fields not specified in
#   this array are assumed to be strings.
#
# [*socket*]
#   Unix domain socket from which ATS request logs are to be read.
#
# === Example
#
# atskafka::instance { 'webrequest':
#     brokers => ['kafka-jumbo1001.eqiad.wmnet:9093', 'kafka-jumbo1002.eqiad.wmnet:9093'],
#     topic   => 'webrequest_text',
#     socket  => '/srv/trafficserver/tls/var/run/analytics.sock',
# }
#
define atskafka::instance(
    Array[String] $brokers           = ['localhost:9092'],
    Stdlib::Absolutepath $stats_dir  = '/var/cache/atskafka',
    Integer $stats_interval_ms       = 60000,
    String $topic                    = 'atskafka_test',
    Array[String] $numeric_fields    = ['time_firstbyte', 'response_size'],
    Stdlib::Absolutepath $socket     = '/var/run/log.socket',
) {
    require ::atskafka

    $kafka_servers = join($brokers, ',')
    $numeric = join($numeric_fields, ',')

    file { $stats_dir:
        ensure => directory,
        mode   => '0755',
    }

    $stats_file = "${stats_dir}/${name}.stats.json"

    systemd::service { "atskafka-${name}":
        content   => systemd_template('atskafka'),
        subscribe => Package['atskafka'],
    }
}
