# == Class role::kafka::analytics::broker
# Sets up a broker belonging to an Analytics cluster.
# This role works for any site.
#
# See modules/role/manifests/kafka/README.md for more information.
#
class role::kafka::analytics::broker {

    require_package('openjdk-7-jdk')

    $config         = kafka_config('analytics')
    $cluster_name   = $config['name']
    $zookeeper_url  = $config['zookeeper']['url']
    $brokers_string = $config['brokers']['string']

    system::role { 'role::kafka::analytics::broker':
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

    # Temporary list of brokers that have been upgraded to the new
    # confluent puppet module.  This will only be here while we
    # perform the upgrade 1 broker at at ime.
    $confluent_brokers = hiera('confluent_brokers', [])
    if $::hostname in $confluent_brokers {
        class { '::confluent::kafka::broker':

            # NOTE: This will be removed once all brokers are on 0.9
            inter_broker_protocol_version   => '0.8.2.X',

            log_dirs                        => $log_dirs,
            brokers                         => $config['brokers']['hash'],
            zookeeper_connect               => $config['zookeeper']['url'],
            nofiles_ulimit                  => $nofiles_ulimit,
            jmx_port                        => $config['jmx_port'],

            # I don't trust auto.leader.rebalance :)
            auto_leader_rebalance_enable    => false,

            default_replication_factor      => 3,

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
            # Use LinkedIn recommended settings with G1 garbage collector,
            jvm_performance_opts            => '-server -XX:PermSize=48m -XX:MaxPermSize=48m -XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35',
        }

        class { '::confluent::kafka::broker::jmxtrans':
            group_prefix => $group_prefix,
            statsd       => hiera('statsd', undef),
        }

        # Monitor kafka in production
        if $::realm == 'production' {
            class { '::confluent::kafka::broker::alerts':
                nagios_servicegroup     => "analytics_${::site}",
                # TODO: tweak these
                replica_maxlag_warning  => '1000000',
                replica_maxlag_critical => '5000000',
            }
        }
    }
    else {
        # export ZOOKEEPER_URL and BROKER_LIST user environment variable.
        # This makes it much more convenient to run kafka commands without having
        # to specify the --zookeeper or --brokers flag every time.
        file { '/etc/profile.d/kafka.sh':
            owner   => 'root',
            mode    => '0444',
            content => template('role/kafka/kafka-profile.sh.erb'),
        }

        class { '::kafka::server':
            log_dirs                        => $log_dirs,
            brokers                         => $config['brokers']['hash'],
            zookeeper_hosts                 => $config['zookeeper']['hosts'],
            zookeeper_chroot                => $config['zookeeper']['chroot'],
            nofiles_ulimit                  => $nofiles_ulimit,
            jmx_port                        => $config['jmx_port'],

            # Enable auto creation of topics.
            auto_create_topics_enable       => true,

            # (Temporarily?) disable auto leader rebalance.
            # I am having issues with analytics1012, and I can't
            # get Camus to consume properly for its preferred partitions
            # if it is online and the leader.  - otto
            auto_leader_rebalance_enable    => false,

            default_replication_factor      => min(3, $config['brokers']['size']),
            # Start with a low number of (auto created) partitions per
            # topic.  This can be increased manually for high volume
            # topics if necessary.
            num_partitions                  => 1,

            # Bump this up to get a little more
            # parallelism between replicas.
            num_replica_fetchers            => 12,
            # Setting this larger so that it is sure to be bigger
            # than batch size from varnishkafka.
            # See: https://issues.apache.org/jira/browse/KAFKA-766
            # webrequest_bits is about 50k msgs/sec, and has 10 partitions.
            # That's 5000 msgs/second/partition, so this should allow
            # a partition to get behind by up to 10 seconds before
            # removing it from the ISR.  This will be longer for
            # less voluminous topics.
            replica_lag_max_messages        => 50000,
            # Setting this to a value according to https://cwiki.apache.org/confluence/display/KAFKA/FAQ#FAQ-HowtoreducechurnsinISR?WhendoesabrokerleavetheISR?
            # 1 / MinFetcHRate * 1000.  I assume this result to be in seconds, since the default for max_ms is 10000.
            # MinFetchRate ~= 45. 1/45*1000 ~= 22.  Setting this to 30 seconds to overcompensate.
            # See also: http://ganglia.wikimedia.org/latest/graph_all_periods.php?title=&vl=&x=&n=&hreg%5B%5D=analytics102%5B12%5D.*&mreg%5B%5D=kafka.server.ReplicaFetcherManager.Replica-MinFetchRate.Value&gtype=line&glegend=show&aggregate=1
            replica_lag_time_max_ms         => 30000,
            # Allow for 16 seconds of latency when talking with Zookeeper.
            # We seen an issue where (mainly or only) analytics1021 will
            # pause for almost 12 seconds for a yet unknown reason.  Upping
            # the session timeout here should give the broker enough time
            # to get back in sync with Zookeeper before it is removed from the ISR.
            # See T83561 (near the bottom)
            # and: http://mail-archives.apache.org/mod_mbox/kafka-users/201407.mbox/%3CCAFbh0Q2f71qgs5JDNFxkm7SSdZyYMH=ZpEOxotuEQfKqeXQHfw@mail.gmail.com%3E
            zookeeper_connection_timeout_ms => 16000,
            zookeeper_session_timeout_ms    => 16000,
            # Use LinkedIn recommended settings with G1 garbage collector,
            jvm_performance_opts            => '-server -XX:PermSize=48m -XX:MaxPermSize=48m -XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35',
        }

        class { '::kafka::server::jmxtrans':
            group_prefix => $group_prefix,
            statsd       => hiera('statsd', undef),
            jmx_port     => $config['jmx_port'],
            require      => Class['::kafka::server'],
        }

        # Monitor kafka in production
        if $::realm == 'production' {
            class { '::kafka::server::monitoring':
                jmx_port            => $config['jmx_port'],
                nagios_servicegroup => "analytics_${::site}",
                group_prefix        => $group_prefix,
            }
        }
    }

    # firewall Kafka Broker
    ferm::service { 'kafka-broker':
        proto  => 'tcp',
        port   => $::kafka::server::broker_port,
        srange => '$ALL_NETWORKS',
    }

    include ::ferm::ipsec_allow

    # Monitor TCP Connection States
    diamond::collector { 'TcpConnStates':
        source => 'puppet:///modules/diamond/collector/tcpconnstates.py',
    }

    # Monitor Ferm/Netfilter Connection Flows
    diamond::collector { 'NfConntrackCount':
        source => 'puppet:///modules/diamond/collector/nf_conntrack_counter.py',
    }
}
