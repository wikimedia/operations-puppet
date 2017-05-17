# == Class profile::kafka::simple::broker
# Sets up a simple Kafka broker instance.
# This is useful for testing Kafka in labs.
#
class profile::kafka::simple::broker {
    system::role { 'profile::kafka::simple::broker':
        description => "Kafka Broker Server in the ${cluster_name} cluster",
    }

    require_package('openjdk-8-jdk')

    # kafkacat is handy!
    require_package('kafkacat')

# TODO: this is broken in labs right now?!
    # $config         = kafka_config('simple')
     # SERVER: undefined method `[]' for nil:NilClass at /etc/puppet/modules/profile/manifests/kafka/simple/broker.pp:17

    $config = {
        'name'      => 'simple-analytics',
        'brokers'   => {
          'hash'     => { 'kafkatest02.analytics.eqiad.wmflabs' => { 'id' => 2 }},
          'array'    => ['kafkatest02.analytics.eqiad.wmflabs'],
          # list of comma-separated host:port broker pairs
          'string'   => 'kafkatest02.analytics.eqiad.wmflabs:9092',
          # list of comma-separated host_9999 broker pairs used as graphite wildcards
          'graphite' => 'kafkatest02_analytics_eqiad_wmflabs_9999',
          'size'     => 1,
        },
        'jmx_port'  => 9999,
        'zookeeper' => {
          'name'   => 'main-eqiad',
          'hosts'  => ['zk1-1.analytics.eqiad.wmflabs'],
          'chroot' => "/kafka/#{cluster_name}",
          'url'    => "zk1-1.analytics.eqiad.wmflabs:2181/kafka/simple-analytics"
        }
    }

    # If we've got at least 3 brokers, set default replication factor to 3.
    $replication_factor  = min(3, $config['brokers']['size'])

    file { '/srv/kafka':
        ensure => 'directory',
        mode   => '0755',
    }

    class { '::confluent::kafka::client':
        # These should be removed once they are the default in ::confluent::kafka module
        scala_version => '2.11',
        kafka_version => '0.10.2.1-1',
        java_home     => '/usr/lib/jvm/java-1.8.0-openjdk-amd64',
    }

    class { '::confluent::kafka::broker':
        log_dirs                   => ['/srv/kafka/data'],
        brokers                    => $config['brokers']['hash'],
        zookeeper_connect          => $config['zookeeper']['url'],
        default_replication_factor => $replication_factor,
        # This can be removed once it is a default in in ::confluent::kafka module
        inter_broker_protocol_version => '0.10.2',
        # Use Kafka/LinkedIn recommended settings with G1 garbage collector.
        # https://kafka.apache.org/documentation/#java
        # Note that MetaspaceSize is a Java 8 setting.
        jvm_performance_opts       => '-server -XX:MetaspaceSize=96m -XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35 -XX:G1HeapRegionSize=16M -XX:MinMetaspaceFreeRatio=50 -XX:MaxMetaspaceFreeRatio=80',
    }
}
