# SPDX-License-Identifier: Apache-2.0
# == define profile::kafka::burrow
#
# Consumer offset lag monitoring tool template for a generic Kafka cluster.
# Compatible only with burrow >= 1.0.
#
define profile::kafka::kafka_kit(
    String $zookeeper_address,
    String $zookeeper_prefix,
    String $zookeeper_metrics_prefix,
    String $kafka_address,
    String $kafka_cluster_prometheus_label,
    String $prometheus_url,
    Hash $brokers,
) {

  $broker_mapping = $brokers.map |$broker, $broker_meta| { "${broker.split('\.')[0]}:9100=${broker_meta['id']}" }.join(',')
  $broker_node_instances = $brokers.map |$broker, $broker_meta| { "${broker.split('\.')[0]}:9100" }.join('|')

  ensure_packages(['kafka-kit', 'kafka-kit-prometheus-metricsfetcher'])
  file { '/etc/profile.d/kafka_kit.sh':
    content => epp('profile/kafka/kafka_kit.sh.epp', {
      zookeeper_address              => $zookeeper_address,
      zookeeper_prefix               => $zookeeper_prefix,
      zookeeper_metrics_prefix       => $zookeeper_metrics_prefix,
      kafka_address                  => $kafka_address,
      kafka_cluster_prometheus_label => $kafka_cluster_prometheus_label,
      prometheus_url                 => $prometheus_url,
      broker_mapping                 => $broker_mapping,
      broker_node_instances          => $broker_node_instances,
    }),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }
}
