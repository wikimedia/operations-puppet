# == Class profile::kafka::simple::broker
# Sets up a simple Kafka broker instance.
# This is useful for testing Kafka in labs.
#
class profile::kafka::simple::broker(
    $kafka_version = hiera('profile::kafka::simple::version'),
) {
    system::role { 'profile::kafka::simple::broker':
        description => "Kafka Broker Server in the ${cluster_name} cluster",
    }

    require_package('openjdk-8-jdk')
    $java_home      = '/usr/lib/jvm/java-1.8.0-openjdk-amd64'

    # kafkacat is handy!
    require_package('kafkacat')

    $config         = kafka_config('simple')
    $cluster_name   = $config['name']
    $zookeeper_url  = $config['zookeeper']['url']
    $brokers_string = $config['brokers']['string']

    # If we've got at least 3 brokers, set default replication factor to 3.
    $replication_factor  = min(3, $config['brokers']['size'])

    file { '/srv/kafka':
        ensure => 'directory',
        mode   => '0755',
    }

    class { '::confluent::kafka::client':
        kafka_version => $kafka_version,
    }

    class { '::confluent::kafka::broker':
        log_dirs                     => ['/srv/kafka/data'],
        brokers                      => $config['brokers']['hash'],
        zookeeper_connect            => $config['zookeeper']['url'],
        default_replication_factor   => $replication_factor,
        # Use Kafka/LinkedIn recommended settings with G1 garbage collector.
        # https://kafka.apache.org/documentation/#java
        # Note that MetaspaceSize is a Java 8 setting.
        jvm_performance_opts         => '-server -XX:MetaspaceSize=96m -XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35 -XX:G1HeapRegionSize=16M -XX:MinMetaspaceFreeRatio=50 -XX:MaxMetaspaceFreeRatio=80',
    }
}
