# == Class role::kafka::analytics::broker
# Sets up a broker belonging to an Analytics cluster.
# This role works for any site.
#
# See modules/role/manifests/kafka/README.md for more information.
#
# filtertags: labs-project-deployment-prep
class role::kafka::analytics::broker {

    require_package('openjdk-7-jdk')
    # kafkacat is handy!
    require_package('kafkacat')

    $config         = kafka_config('analytics')
    $cluster_name   = $config['name']
    $zookeeper_url  = $config['zookeeper']['url']
    $brokers_string = $config['brokers']['string']

    system::role { 'kafka::analytics::broker':
        description => "Kafka Broker Server in the ${cluster_name} cluster",
    }

    $log_dirs = $::realm ? {
        'labs'       => ['/var/spool/kafka'],
        # Production analytics Kafka brokers have more disks.
        'production' => [
            '/var/spool/kafka/a/data',
            '/var/spool/kafka/b/data',
            '/var/spool/kafka/c/data',
            '/var/spool/kafka/d/data',
            '/var/spool/kafka/e/data',
            '/var/spool/kafka/f/data',
            '/var/spool/kafka/g/data',
            '/var/spool/kafka/h/data',
            '/var/spool/kafka/i/data',
            '/var/spool/kafka/j/data',
            '/var/spool/kafka/k/data',
            '/var/spool/kafka/l/data',
        ],
    }

    $nofiles_ulimit = $::realm ? {
        # Use default ulimit for labs kafka
        'labs'       => 8192,
        # Increase ulimit for production kafka.
        'production' => 65536,
    }

    # Historically there was only one kafka cluster in eqiad.
    # This cluster was named 'eqiad'.  For the metrics, let's display
    # a 'logical' cluster name of analytics-eqiad.
    if ($::realm == 'production' and $::site == 'eqiad') {
        $group_prefix = 'kafka.cluster.analytics-eqiad.'
    }
    else {
        $group_prefix = "kafka.cluster.${cluster_name}."
    }

    class { '::confluent::kafka::common':
        scala_version => '2.11.7',
        kafka_version => '0.9.0.1-1',
    }

    class { '::confluent::kafka::broker':
        log_dirs                        => $log_dirs,
        brokers                         => $config['brokers']['hash'],
        zookeeper_connect               => $config['zookeeper']['url'],
        nofiles_ulimit                  => $nofiles_ulimit,
        jmx_port                        => $config['jmx_port'],

        # I don't trust auto.leader.rebalance :)
        auto_leader_rebalance_enable    => false,

        default_replication_factor      => min(3, $config['brokers']['size']),

        # Should be changed if brokers are upgraded.
        inter_broker_protocol_version   => '0.9.0.X',

        # The default for log segment bytes has changed in the puppet
        # module / packaging.  536870912 is what we have always used on
        # analytics brokers, no need to change it now.
        log_segment_bytes               => 536870912,
        # Bump this up to get a little more
        # parallelism between replicas.
        num_replica_fetchers            => 12,
        # Setting this to a value according to https://cwiki.apache.org/confluence/display/KAFKA/FAQ#FAQ-HowtoreducechurnsinISR?WhendoesabrokerleavetheISR?
        # 1 / MinFetcHRate * 1000.  I assume this result to be in seconds,
        # since the default for max_ms is 10000.
        # MinFetchRate ~= 45. 1/45*1000 ~= 22.  Setting this to 30 seconds
        # to overcompensate.
        # See also: http://ganglia.wikimedia.org/latest/graph_all_periods.php?title=&vl=&x=&n=&hreg%5B%5D=analytics102%5B12%5D.*&mreg%5B%5D=kafka.server.ReplicaFetcherManager.Replica-MinFetchRate.Value&gtype=line&glegend=show&aggregate=1
        replica_lag_time_max_ms         => 30000,
        # Allow for 16 seconds of latency when talking with Zookeeper.
        # We seen an issue where (mainly or only) analytics1021 will
        # pause for almost 12 seconds for a yet unknown reason.  Upping
        # the session timeout here should give the broker enough time
        # to get back in sync with Zookeeper before it is removed from the
        # ISR. See T83561 (near the bottom) and:
        # http://mail-archives.apache.org/mod_mbox/kafka-users/201407.mbox/%3CCAFbh0Q2f71qgs5JDNFxkm7SSdZyYMH=ZpEOxotuEQfKqeXQHfw@mail.gmail.com%3E
        log_flush_interval_ms           => 3000,
        zookeeper_connection_timeout_ms => 16000,
        zookeeper_session_timeout_ms    => 16000,
        # Setting maximum partition size for a topic to 350GiB
        # This should guarantee 4 big partitions like text/upload to co-exist
        # on the same disk partition leaving enough space for other ones.
        # More info in: T136690
        log_retention_bytes             => hiera('confluent::kafka::broker::log_retention_bytes', 375809638400),
        log_retention_hours             => hiera('confluent::kafka::broker::log_retention_hours', 168),
        # Use LinkedIn recommended settings with G1 garbage collector,
        jvm_performance_opts            => '-server -XX:PermSize=48m -XX:MaxPermSize=48m -XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35',

        # These defaults are set to keep no-ops from changes
        # made in confluent module for T166162.
        # They should be removed (since they are the kafka or module defaults)
        # when this role gets converted to a profile.
        replica_fetch_max_bytes         => 1048576,
        log_flush_interval_messages     => 10000,
        log_cleanup_policy              => 'delete',

        # FIXME: this needs to be refactored when the role
        # is moved to profiles.
        message_max_bytes               => hiera('kafka_message_max_bytes', 1048576),
    }

    class { '::confluent::kafka::broker::jmxtrans':
        ensure       => 'absent',
        group_prefix => $group_prefix,
        statsd       => hiera('statsd', undef),
    }

    # Monitor kafka in production
    if $::realm == 'production' {
        class { '::confluent::kafka::broker::alerts':
            ensure                  => 'absent',
            nagios_servicegroup     => "analytics_${::site}",
            nrpe_contact_group      => 'admins,analytics',
            # TODO: tweak these
            replica_maxlag_warning  => '1000000',
            replica_maxlag_critical => '5000000',
        }
    }
    # firewall Kafka Broker
    ferm::service { 'kafka-broker':
        proto   => 'tcp',
        # TODO: $::confluent::kafka::broker::port doesn't
        # seem to work as expected.  Hardcoding this for now.
        port    => 9092,
        notrack => true,
        srange  => '($PRODUCTION_NETWORKS $FRACK_NETWORKS)',
    }

    # In case of mediawiki spikes we've been seeing up to 300k connections,
    # so raise the connection table size on Kafka brokers (default is 256k)
    sysctl::parameters { 'kafka_conntrack':
        values   => {
            'net.netfilter.nf_conntrack_max' => 524288,
        },
        priority => 75,
    }
}
