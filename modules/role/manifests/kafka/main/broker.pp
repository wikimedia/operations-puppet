# == Class role::kafka::main::broker
# Sets up a broker belonging to a main Kafka cluster.
# This role works for any site.
#
# See modules/role/manifests/kafka/README.md for more information.
#
class role::kafka::main::broker {

    require_package('openjdk-7-jdk')

    $config         = kafka_config('main')
    $cluster_name   = $config['name']
    $zookeeper_url  = $config['zookeeper']['url']
    $brokers_string = $config['brokers']['string']

    system::role { 'role::kafka::main::broker':
        description => "Kafka Broker Server in the ${cluster_name} cluster",
    }

    # export ZOOKEEPER_URL and BROKER_LIST user environment variable.
    # This makes it much more convenient to run kafka commands without having
    # to specify the --zookeeper or --brokers flag every time.
    file { '/etc/profile.d/kafka.sh':
        owner   => 'root',
        mode    => '0444',
        content => template('role/kafka/kafka-profile.sh.erb'),
    }

    $nofiles_ulimit = $::realm ? {
        # Use default ulimit for labs kafka
        'labs'       => 8192,
        # Increase ulimit for production kafka.
        'production' => 65536,
    }

    file { '/srv/kafka':
        ensure => 'directory',
        mode   => '0755',
    }

    class { '::kafka::server':
        log_dirs                     => ['/srv/kafka/data'],
        brokers                      => $config['brokers']['hash'],
        zookeeper_hosts              => $config['zookeeper']['hosts'],
        zookeeper_chroot             => $config['zookeeper']['chroot'],
        nofiles_ulimit               => $nofiles_ulimit,
        jmx_port                     => $config['jmx_port'],

        # Enable auto creation of topics.
        auto_create_topics_enable    => true,

        # (Temporarily?) disable auto leader rebalance.
        # I am having issues with analytics1012, and I can't
        # get Camus to consume properly for its preferred partitions
        # if it is online and the leader.  - otto
        auto_leader_rebalance_enable => false,

        default_replication_factor   => min(3, $config['brokers']['size']),
        # Start with a low number of (auto created) partitions per
        # topic.  This can be increased manually for high volume
        # topics if necessary.
        num_partitions               => 1,

        # Use LinkedIn recommended settings with G1 garbage collector,
        jvm_performance_opts         => '-server -XX:PermSize=48m -XX:MaxPermSize=48m -XX:+UseG1GC -XX:MaxGCPauseMillis=20 -XX:InitiatingHeapOccupancyPercent=35',
    }

    # firewall Kafka Broker
    ferm::service { 'kafka-broker':
        proto  => 'tcp',
        port   => $::kafka::server::broker_port,
        srange => '$DOMAIN_NETWORKS',
    }

    # Include Kafka Server Jmxtrans class
    # to send Kafka Broker metrics to Ganglia and statsd.
    $group_prefix = "kafka.cluster.${cluster_name}."
    class { '::kafka::server::jmxtrans':
        group_prefix => $group_prefix,
        statsd       => hiera('statsd', undef),
        jmx_port     => $config['jmx_port'],
        require      => Class['::kafka::server'],
    }

    # Monitor kafka in production
    if $::realm == 'production' {
        class { '::kafka::server::monitoring':
            jmx_port     => $config['jmx_port'],
            group_prefix => $group_prefix,
        }
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
