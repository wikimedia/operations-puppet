# SPDX-License-Identifier: Apache-2.0
# == define profile::kafka::burrow
#
# Consumer offset lag monitoring tool template for a generic Kafka cluster.
# Compatible only with burrow >= 1.0.
#
define profile::kafka::kafka_kit(
    String $zookeeper_address,
    String $zookeeper_prefix,
    String $kafka_address,
) {
  ensure_packages(['kafka-kit'])
  file { '/etc/profile.d/kafka_kit.sh':
    content => epp('profile/kafka/kafka_kit.sh.epp', {
      zookeeper_address => $zookeeper_address,
      zookeeper_prefix  => $zookeeper_prefix,
      kafka_address     => $kafka_address
    }),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }
}
