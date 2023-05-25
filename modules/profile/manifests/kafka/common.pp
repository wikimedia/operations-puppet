# SPDX-License-Identifier: Apache-2.0
# == Class profile::kafka::common
#
# Common configuration for Kafka brokers and mirror maker istances.
#
class profile::kafka::common {

    $kafka_dir = '/etc/kafka'
    $kafka_ssl_dir = '/etc/kafka/ssl'
    # The kafka directory is deployed via the Confluent
    # kafka packages (May 2023). To ease the development of
    # puppet classes (and their dependencies), we explicitly
    # create the directory as well.
    file{ [$kafka_dir, $kafka_ssl_dir]:
        ensure => directory,
        owner  => 'kafka',
        group  => 'kafka',
        mode   => '0755',
    }
}
