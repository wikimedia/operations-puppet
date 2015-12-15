# role/analytics/kafka.pp
#
# Role classes for Analytics Kakfa nodes.
# These role classes will configure Kafka properly in either
# the Analytics labs or Analytics production environments.
#
# Usage:
#
# If you only need the Kafka package and configs to use the
# Kafka client to talk to Kafka Broker Servers:
#
#   include role::analytics::kafka::client
#
# If you want to set up a Kafka Broker Server
#   include role::analytics::kafka::server
#
class role::analytics::kafka::config {
    if ($::realm == 'labs') {
        # In labs, this can be set via hiera, or default to $::labsproject
        $kafka_cluster_name = hiera('role::analytics::kafka::config::kafka_cluster_name', $::labsproject)

        # Look up cluster config via hiera.
        # This will default to configuring a kafka cluster named
        # after $::labsproject with a single kafka broker
        # that is the current host
        $cluster_config = hiera(
            'role::analytics::kafka::config::cluster_config',
            {
                "${kafka_cluster_name}" => {
                    "${::fqdn}" => { 'id' => 1 },
                },
            }
        )

        # labs only uses a single log_dir
        $log_dirs = ['/var/spool/kafka']

        # No ganglia in labs (?)
        $ganglia   = undef
        # TODO: use variables for statsd server from somewhere?
        $statsd = 'labmon1001.eqiad.wmnet:8125'

        # Use default ulimit for labs kafka
        $nofiles_ulimit = 8192
    }

    else {
        # Production only has one Kafka cluster in eqiad, so
        # hardcode the cluster name to 'eqiad'.
        $kafka_cluster_name = 'eqiad'

        # Production Kafka clusters are named by $::site.
        $cluster_config = {
            'eqiad'   => {
                'kafka1012.eqiad.wmnet' => { 'id' => 12 },  # Row A
                'kafka1013.eqiad.wmnet' => { 'id' => 13 },  # Row A
                'kafka1014.eqiad.wmnet' => { 'id' => 14 },  # Row C
                'kafka1018.eqiad.wmnet' => { 'id' => 18 },  # Row D
                'kafka1020.eqiad.wmnet' => { 'id' => 20 },  # Row D
                'kafka1022.eqiad.wmnet' => { 'id' => 22 },  # Row C
            },
            'ulsfo' => { },
            'esams' => { },
        }

        $log_dirs = [
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
        ]
        # Ganglia diskstat plugin would like to know what disks to monitor
        $log_disks = ['sda',
                    'sdb',
                    'sdc',
                    'sdd',
                    'sde',
                    'sdf',
                    'sdg',
                    'sdh',
                    'sdi',
                    'sdj',
                    'sdk',
                    'sdl',
                ]

        # TODO: use variables from new ganglia module once it is finished.
        $ganglia   = '208.80.154.10:9694'
        # TODO: use variables for stats server from somewhere?
        $statsd  = 'statsd.eqiad.wmnet:8125'


        # Increase ulimit for production kafka.
        $nofiles_ulimit = 65536
    }

    $brokers          = $cluster_config[$kafka_cluster_name]
    if is_hash($brokers) {
        $brokers_array = keys($brokers)
    } else {
        $brokers_array = []
    }

    $jmx_port         = 9999

    # jmxtrans renders hostname metrics with underscores and
    # suffixed with the jmx port.  Build a graphite
    # wildcard to match these.
    # E.g. kafka1012.eqiad.wmnet -> kafka1012_eqiad_wmnet_9999
    $brokers_graphite_wildcard = inline_template('{<%= @brokers_array.join("_#{@jmx_port},").tr(".","_") + "_#{@jmx_port}" %>}')

    $zookeeper_hosts  = keys(hiera('zookeeper_hosts'))
    $zookeeper_chroot = "/kafka/${kafka_cluster_name}"
    $zookeeper_url    = inline_template("<%= @zookeeper_hosts.sort.join(',') %><%= @zookeeper_chroot %>")
}

# == Class role::analytics::kafka::client
#
class role::analytics::kafka::client inherits role::analytics::kafka::config {
    require_package('openjdk-7-jdk')

    # include kafka package
    include kafka

    # Let's go ahead and export a ZOOKEEPER_URL user environment variable.
    # This makes it much more convenient to run kafka commands without having
    # to specify the --zookeeper flag every time.
    file { '/etc/profile.d/kafka.sh':
        owner   => 'root',
        mode    => '0444',
        content => "# NOTE:  This file is managed by Puppet\nexport ZOOKEEPER_URL='${zookeeper_url}'",
    }
}

# == Class role::analytics::kafka::server
#
class role::analytics::kafka::server inherits role::analytics::kafka::client {
    system::role { 'role::analytics::kafka::server':
        description => 'Kafka Broker Server'
    }

    class { '::kafka::server':
        log_dirs                        => $log_dirs,
        brokers                         => $brokers,
        zookeeper_hosts                 => $zookeeper_hosts,
        zookeeper_chroot                => $zookeeper_chroot,
        nofiles_ulimit                  => $nofiles_ulimit,
        jmx_port                        => $jmx_port,

        # Enable auto creation of topics.
        auto_create_topics_enable       => true,

        # (Temporarily?) disable auto leader rebalance.
        # I am having issues with analytics1012, and I can't
        # get Camus to consume properly for its preferred partitions
        # if it is online and the leader.  - otto
        auto_leader_rebalance_enable    => false,

        default_replication_factor      => min(3, size($brokers_array)),
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


    # Include Kafka Server Jmxtrans class
    # to send Kafka Broker metrics to Ganglia and statsd.
    class { '::kafka::server::jmxtrans':
        ganglia  => $ganglia,
        statsd   => $statsd,
        jmx_port => $jmx_port,
    }

    # Monitor kafka in production
    if $::realm == 'production' {
        class { '::kafka::server::monitoring':
            nagios_servicegroup => 'analytics_eqiad',
        }

        #firewall Kafka Broker
        ferm::service { 'kafka-server':
            proto  => 'tcp',
            port   => '9092',
            srange => '$ALL_NETWORKS',
        }

        #firewall allow ipsec esp
        ferm::service { 'kafka-ipsec-esp':
            proto  => 'esp',
            srange => '$ALL_NETWORKS',
        }

        #firewall allow ipsec ike udp 500
        ferm::service { 'kafka-ipsec-ike':
            proto  => 'udp',
            port   => '500',
            srange => '$ALL_NETWORKS',
        }
    }
}
