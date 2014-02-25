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
    require role::analytics::zookeeper::config

    # This allows labs to set the $::kafka_cluster global,
    # which will conditionally select labs hosts to include
    # in a Kafka cluster.  This allows us to test cross datacenter
    # broker mirroring with multiple clusters.
    $kafka_cluster_name = $::kafka_cluster ? {
        undef     => $::site,
        default   => $::kafka_cluster,
    }

    if ($::realm == 'labs') {
        # TODO: Make hostnames configurable via labs global variables.
        $cluster = {
            'main'     => {
                'kafka-main1.pmtpa.wmflabs'     => { 'id' => 1 },
                'kafka-main2.pmtpa.wmflabs'     => { 'id' => 2 },
            },
            'external'                          => {
                'kafka-external1.pmtpa.wmflabs' => { 'id' => 10 },
            },
        }
        # labs only uses a single log_dir
        $log_dirs = ['/var/spool/kafka']
        # TODO: use variables from new ganglia module once it is finished.
        $ganglia_host   = 'aggregator1.pmtpa.wmflabs'
        $ganglia_port   = 50090

        # Use default ulimit for labs kafka
        $nofiles_ulimit = 8192
    }

    # else Kafka cluster is based on $::site.
    else {
        $cluster = {
            'eqiad'   => {
                'analytics1021.eqiad.wmnet' => { 'id' => 21 },
                'analytics1022.eqiad.wmnet' => { 'id' => 22 },
            },
            'ulsfo' => { },
            'pmtpa' => { },
            'esams' => { },
        }

        # production Kafka uses a bunch of JBOD log_dir mounts.
        $log_dirs = [
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
        # TODO: use variables from new ganglia module once it is finished.
        $ganglia_host   = '239.192.1.32'
        $ganglia_port   = 8649

        # Increase ulimit for production kafka.
        $nofiles_ulimit = 65536
    }

    $brokers          = $cluster[$kafka_cluster_name]
    $brokers_array    = keys($brokers)
    $zookeeper_hosts  = $role::analytics::zookeeper::config::hosts_array
    $zookeeper_chroot = "/kafka/${kafka_cluster_name}"
    $zookeeper_url    = inline_template("<%= zookeeper_hosts.sort.join(',') %><%= zookeeper_chroot %>")
}

# == Class role::analytics::kafka::client
#
class role::analytics::kafka::client inherits role::analytics::kafka::config {
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
    class { '::kafka::server':
        log_dirs                        => $log_dirs,
        brokers                         => $brokers,
        zookeeper_hosts                 => $zookeeper_hosts,
        zookeeper_chroot                => $zookeeper_chroot,
        nofiles_ulimit                  => $nofiles_ulimit,
        # Bump this up to 2 to get a little more
        # parallelism between replicas.
        num_replica_fetchers            => 2,
        # Setting this larger so that it is sure to be bigger
        # than batch size from varnishkafka.
        # See: https://issues.apache.org/jira/browse/KAFKA-766
        replica_lag_max_messages        => 10000,
    }

    # Generate icinga alert if Kafka Server is not running.
    nrpe::monitor_service { 'kafka':
        description  => 'Kafka Broker Server',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "kafka.Kafka /etc/kafka/server.properties"',
        require      => Class['::kafka::server'],
    }

    $jmxtrans_outfile = '/var/log/kafka/kafka-jmx.log'
    file { $jmxtrans_outfile:
        ensure  => 'present',
        owner   => 'jmxtrans',
        group   => 'jmxtrans',
        mode    => '0644',
        require => [Package['jmxtrans'], Package['kafka']]
    }

    # Include Kafka Server Jmxtrans class
    # to send Kafka Broker metrics to Ganglia.
    # We also save metrics to an logfile for easy
    # debugging.
    class { '::kafka::server::jmxtrans':
        ganglia => "${ganglia_host}:${ganglia_port}",
        outfile => $jmxtrans_outfile
    }

    # Install a logrotate.d file for the jmx.log file
    file { '/etc/logrotate.d/kafka-jmx':
        content =>
"${jmxtrans_outfile} {
    size 100M
    rotate 2
    missingok
    create 0644 jmxtrans jmxtrans
}
"
    }

    # Generate icinga alert if this jmxtrans instance is not running.
    nrpe::monitor_service { 'jmxtrans':
        description  => 'jmxtrans',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "-jar jmxtrans-all.jar"',
        require      => Class['::kafka::server::jmxtrans'],
    }

    # Set up icinga monitoring of Kafka broker per second.
    # If this drops too low, trigger an alert.
    # These thresholds have to be manually set.
    # adjust them if you add or remove data from Kafka topics.
    monitor_ganglia { 'kafka-broker-MessagesIn':
        description => 'Kafka Broker Messages In',
        metric      => 'kafka.server.BrokerTopicMetrics.AllTopicsMessagesInPerSec.FifteenMinuteRate',
        warning     => ':1500.0',
        critical    => ':1000.0',
        require     => Class['::kafka::server::jmxtrans'],
    }

    # Alert if any Kafka has under replicated partitions.
    # If it does, this means a broker replica is falling behind
    # and will be removed from the ISR.
    monitor_ganglia { 'kafka-broker-UnderReplicatedPartitions':
        description => 'Kafka Broker Under Replicated Partitions',
        metric      => 'kafka.server.ReplicaManager.UnderReplicatedPartitions.Value',
        # Any under replicated partitions are bad.
        # Over 10 means (probably) that at least an entire topic
        # is under replicated.
        warning     => '1',
        critical    => '10',
        require     => Class['::kafka::server::jmxtrans'],
    }

    # Alert if any Kafka Broker replica lag is too high
    monitor_ganglia { 'kafka-broker-Replica-MaxLag':
        description => 'Kafka Broker Replica Lag',
        metric      => 'kafka.server.ReplicaFetcherManager.Replica-MaxLag.Value',
        # As of 2014-02 replag could catch up at more than 1000 msgs / sec,
        # (probably more like 2 or 3 K / second). At that rate, 1M messages
        # behind should catch back up in at least 30 minutes.
        warning     => '1000000',
        critical    => '5000000',
        require     => Class['::kafka::server::jmxtrans'],
    }
}
