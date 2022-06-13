# SPDX-License-Identifier: Apache-2.0
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
# [*topic*]
#   Kafka topic to which all logs must be written.
#
# [*stats_interval_ms*]
#   statistics.interval.ms in librdkafka: statistics emit interval in
#   milliseconds. A value of 0 disables statistics. (Default: 0)
#
# [*buffering_ms*]
#   queue.buffering.max.ms in librdkafka. How long to wait, in milliseconds,
#   for messages in the producer queue to accumulate before constructing
#   MessageSets to transmit to brokers. A higher value allows larger and more
#   effective (less overhead, improved compression) batches of messages to
#   accumulate at the expense of increased message delivery latency.
#   (Default: 5)
#
# [*buffering_max_messages*]
#   queue.buffering.max.messages in librdkafka. Maximum number of messages
#   allowed on the producer queue. The queue is shared by all topics and
#   partitions. (Default: 100000)
#
# [*batch_num_messages*]
#   batch.num.messages in librdkafka. Maximum number of messages batched in one
#   MessageSet. (Default: 10000)
#
# [*send_max_retries*]
#   message.send.max.retries in librdkafka. How many times to retry sending a
#   failing Message. (Default: 2)
#
# [*send_buffer_bytes*]
#   socket.send.buffer.bytes in librdkafka. Broker socket send buffer size.
#   System default is used if 0. (Default: 0)
#
# [*request_required_acks*]
#   request.required.acks in librdkafka. The number of acknowledgements the
#   leader broker must receive from ISR brokers before responding to the
#   request: 0=Broker does not send any response/ack to client, -1=Broker will
#   block until message is committed by all in sync replicas (ISRs). If there
#   are less than min.insync.replicas (broker configuration) in the ISR set the
#   produce request will fail. (Default: -1)
#
# [*request_timeout_ms*]
#   request.timeout.ms in librdkafka. The ack timeout of the producer request
#   in milliseconds. (Default: 5000)
#
# [*message_timeout_ms*]
#   message.timeout.ms in librdkafka. The maximum time librdkafka may use to
#   deliver a message (including retries). Delivery error occurs when either
#   the retry count or the message timeout are exceeded. (Default: 300000)
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
    String $topic                                     = 'atskafka_test',
    Integer $stats_interval_ms                        = 0,
    Integer $buffering_ms                             = 5,
    Integer $buffering_max_messages                   = 100000,
    Integer $batch_num_messages                       = 10000,
    Integer $send_max_retries                         = 2,
    Integer $send_buffer_bytes                        = 0,
    Integer $request_required_acks                    = -1,
    Integer $request_timeout_ms                       = 5000,
    Integer $message_timeout_ms                       = 300000,
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
