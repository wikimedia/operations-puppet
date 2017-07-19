# == Class profile::zookeeper::firewall::main
#
# Firewall rules for the zookeeper main clusters in codfw and eqiad.
# These Zookeeper clusters need to be available for various services:
# * Analytics Kafka cluster
# * Hadoop HDFS/Yarn Master nodes
# * EventBus Main Kafka clusters (eventbus)
# * Druid nodes
# * Kafka Burrow consumer lag alerting
#
class profile::zookeeper::firewall::main {

    ferm::service { 'zookeeper':
        proto  => 'tcp',
        # Zookeeper client, protocol ports
        port   => '(2181 2182 2183)',
        srange => '(($HADOOP_MASTERS $KAFKA_BROKERS_ANALYTICS $KAFKA_BROKERS_MAIN $DRUID_HOSTS @resolve(krypton.eqiad.wmnet)))',
    }
}