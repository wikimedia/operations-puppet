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
# [*stats_interval_ms*]
#   Flush rdkafka statistics every stats_interval_ms.
#
# [*buffering_ms*]
#   How long to wait, in milliseconds, for messages in the producer queue to
#   accumulate before constructing MessageSets to transmit to brokers. A higher
#   value allows larger and more effective (less overhead, improved
#   compression) batches of messages to accumulate at the expense of increased
#   message delivery latency.
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
# [*conf_file*]
#   Configuration file for rdkafka settings.
#
# [*compression_codec*]
#   Compress messages before sending them to kafka with a specific codec.
#   Default: 'snappy'
#
# [*tls*]
#   Optional configuration to connect to brokers using TLS for authentication
#   and encryption. If left unspecified, the connection to the brokers will be
#   established without authentication and data will be sent in clear.
#   (default: undef).
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
    Array[String] $brokers                            = ['localhost:9092'],
    Integer $stats_interval_ms                        = 60000,
    Integer $buffering_ms                             = 200,
    String $topic                                     = 'atskafka_test',
    Array[String] $numeric_fields                     = ['time_firstbyte', 'response_size'],
    Stdlib::Absolutepath $socket                      = '/var/run/log.socket',
    Stdlib::Absolutepath $conf_file                   = "/etc/atskafka-${name}.conf",
    Enum['snappy', 'gzip', 'none'] $compression_codec = 'snappy',
    Optional[ATSkafka::TLS_settings] $tls             = undef,
) {
    require ::atskafka

    $kafka_servers = join($brokers, ',')
    $numeric = join($numeric_fields, ',')

    file { $conf_file:
        mode    => '0400',
        notify  => Service["atskafka-${name}"],
        content => template('atskafka/atskafka.conf.erb'),
    }

    systemd::service { "atskafka-${name}":
        content   => systemd_template('atskafka'),
        subscribe => Package['atskafka'],
    }
}
