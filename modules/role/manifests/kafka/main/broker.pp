# == Class role::kafka::main::broker
# Sets up a broker belonging to a main Kafka cluster.
# This role works for any site.
#
# See modules/role/manifests/kafka/README.md for more information.
#
# filtertags: labs-project-deployment-prep labs-project-analytics
class role::kafka::main::broker {

    require_package('openjdk-7-jdk')
    # kafkacat is handy!
    require_package('kafkacat')

    $config         = kafka_config('main')
    $cluster_name   = $config['name']
    $zookeeper_url  = $config['zookeeper']['url']
    $brokers_string = $config['brokers']['string']

    system::role { 'role::kafka::main::broker':
        description => "Kafka Broker Server in the ${cluster_name} cluster",
    }

    $nofiles_ulimit = $::realm ? {
        # Use default ulimit for labs kafka
        'labs'       => 8192,
        # Increase ulimit for production kafka.
        'production' => 65536,
    }

    # If we've got at least 3 brokers, set default replication factor to 3.
    $replication_factor  = min(3, $config['brokers']['size'])

    file { '/srv/kafka':
        ensure => 'directory',
        mode   => '0755',
    }

    class { '::confluent::kafka::broker':
        log_dirs                     => ['/srv/kafka/data'],
        brokers                      => $config['brokers']['hash'],
        zookeeper_connect            => $config['zookeeper']['url'],
        nofiles_ulimit               => $nofiles_ulimit,
        jmx_port                     => $config['jmx_port'],

        # I don't trust auto.leader.rebalance :)
        auto_leader_rebalance_enable => false,

        default_replication_factor   => $replication_factor,
        # Start with a low number of (auto created) partitions per
        # topic.  This can be increased manually for high volume
        # topics if necessary.
        num_partitions               => 1,

        # Use LinkedIn recommended settings with G1 garbage collector.
        jvm_performance_opts         => '-server -XX:PermSize=48m -XX:MaxPermSize=48m -XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35',
    }

    # Include Kafka Broker Jmxtrans class to
    # send broker metrics to statsd.
    $group_prefix = "kafka.cluster.${cluster_name}."
    class { '::confluent::kafka::broker::jmxtrans':
        group_prefix => $group_prefix,
        statsd       => hiera('statsd', undef),
    }

    # Monitor kafka in production.
    if $::realm == 'production' {
        class { '::confluent::kafka::broker::alerts': }
    }

    # firewall Kafka Broker.
    ferm::service { 'kafka-broker':
        proto  => 'tcp',
        # TODO: $::confluent::kafka::broker::port doesn't
        # seem to work as expected.  Hardcoding this for now.
        port   => 9092,
        srange => '$PRODUCTION_NETWORKS',
    }


    # Monitor TCP Connection States
    diamond::collector { 'TcpConnStates':
        source => 'puppet:///modules/diamond/collector/tcpconnstates.py',
    }

    # Monitor Ferm/Netfilter Connection Flows
    diamond::collector { 'NfConntrackCount':
        source => 'puppet:///modules/diamond/collector/nf_conntrack_counter.py',
    }
}
