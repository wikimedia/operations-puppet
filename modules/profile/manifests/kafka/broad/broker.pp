# == Class profile::kafka::broad::broker
# Sets up a broad Kafka broker instance.
# A 'broad' Kafka cluster is meant to handle large volues of data
# for many use cases.  It contrasts with the 'main' Kafka cluster(s),
# Which are intended for low-ish volume critical production use.
#
# A broad Kafka cluster is produced to directly by some clients.  It
# Also replicates data from other Kafka clusters using Kafka MirrorMaker.
#
# TODO: Bikeshed this profile / kafka cluster name:
# https://etherpad.wikimedia.org/p/analytics-ops-kafka
#
class profile::kafka::broad::broker(
    $plaintext = hiera('profile::kafka::broad::broker::plaintext'),
    $tls       = hiera('profile::kafka::broad::broker::tls'),
    $tls_key_password = hiera('profile::kafka::broad::broker::tls_key_password')
) {
    $config         = kafka_config('broad')
    $cluster_name   = $config['name']
    $zookeeper_url  = $config['zookeeper']['url']
    $brokers_string = $config['brokers']['string']

    system::role { 'profile::kafka::broad::broker':
        description => "Kafka Broker Server in the ${cluster_name} Kafka cluster",
    }

    require_package('openjdk-8-jdk')

    # kafkacat is handy!
    require_package('kafkacat')

    # Conditionally set $listeners and $ssl_client_auth
    # based on values of $tls and $plaintext.
    if $tls and $plaintext {
        $listeners = [
            'PLAINTEXT://:9092',
            'SSL://:9093',
        ]
        $ssl_client_auth = 'requested'
    }
    else if $plaintext {
        $listeners = ['PLAINTEXT://:9092']
        $ssl_client_auth = 'none'
    }
    else if $tls {
        $listeners = ['SSL://:9093']
        $ssl_client_auth = 'required'
    }
    else {
        fatal('Must set at least one of $plaintext or $ssl to true')
    }


    if $tls {
        # Distribute the Java keystores for this broker's certificate.
        # These need to have been generated with ca-manager and
        # checked into the Puppet private repo in
        # modules/secret/secrets/kafka/broad/...
        ::ca::certs { "kafka/broad/${::fqdn}":
            destination => '/etc/kafka/tls',
            owner       => 'kafka',
        }

        $security_inter_broker_protocol = 'SSL'
        $ssl_keystore_location          = "/etc/kafka/tls/${::fqdn}.jks"
        $ssl_keystore_password          = $tls_key_password
        $ssl_key_password               = $tls_key_password
        $ssl_truststore_location        = "/etc/kafka/tls/truststore.jks"
        $ssl_truststore_password        = $tls_key_password
    }
    else {
        $security_inter_broker_protocol = undef
        $ssl_keystore_location          = undef
        $ssl_keystore_password          = undef
        $ssl_key_password               = undef
        $ssl_truststore_location        = undef
        $ssl_truststore_password        = undef
    }

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
        # TODO: configure log_dirs differently in labs than in prod?
        # make this a hiera variable parameter?
        log_dirs                   => ['/srv/kafka/data'],
        brokers                    => $config['brokers']['hash'],
        zookeeper_connect          => $config['zookeeper']['url'],
        default_replication_factor => min(3, $config['brokers']['size'])
        # This can be removed once it is a default in in ::confluent::kafka module
        inter_broker_protocol_version => '0.10.2',
        # Use Kafka/LinkedIn recommended settings with G1 garbage collector.
        # https://kafka.apache.org/documentation/#java
        # Note that MetaspaceSize is a Java 8 setting.
        jvm_performance_opts       => '-server -XX:MetaspaceSize=96m -XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35 -XX:G1HeapRegionSize=16M -XX:MinMetaspaceFreeRatio=50 -XX:MaxMetaspaceFreeRatio=80',

        listeners                      => $listeners,
        security_inter_broker_protocol => $security_inter_broker_protocol,
        ssl_keystore_location          => $ssl_keystore_location,
        ssl_keystore_password          => $ssl_keystore_password,
        ssl_key_password               => $ssl_key_password,
        ssl_truststore_location        => $ssl_truststore_location,
        ssl_truststore_password        => $ssl_truststore_password,
        ssl_client_auth                => $ssl_client_auth,
    }
}
