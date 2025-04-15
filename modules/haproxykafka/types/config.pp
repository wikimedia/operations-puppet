# SPDX-License-Identifier: Apache-2.0
# @summary haproxykafka main configuration struct.
#
# @param workers
#   Number of workers to spawn for log processing.
#
# @param message_buffer
#   Message buffer size expressed as float (eg. 1e6).
#   Defines the maximum number of error events to receive before
#   returning an error.
#
# @param sdid
#   The SD-ID element as defined by RFC5424 format (must match)
#   the one set in Haproxy configuration.
#
# @param socket
#   Haproxykafka::Socket element containing configuration for the
#   listening socket.
#
# @param logparser
#   Haproxykafka::Logparser element containing configuration for the
#   log parser pipeline section.
#
# @param kafka
#   Haproxykafka::Kafka element containing configuration for the producer
#   pipeline element, including librdkafka configuration.
#
# @param monitoring
#   Haproxykafka::Monitoring element containing configuration for prometheus
#   and internal debug elements.
#
# @param transform_rules
#   Haproxykafka::Transformrules element containing configuration for various
#   rules in the transformation pipeline section.
#

type Haproxykafka::Config = Struct[{
    'workers'             => Integer[1,192],
    'message_buffer'      => Float,
    'sdid'                => String,
    'hostname'            => String,
    'socket'              => Haproxykafka::Socket,
    'logparser'           => Haproxykafka::Logparser,
    'kafka'               => Haproxykafka::Kafka,
    'monitoring'          => Haproxykafka::Monitoring,
    'transform_rules'     => Haproxykafka::Transformrules,
}]
