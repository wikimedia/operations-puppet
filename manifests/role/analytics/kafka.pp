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
        $ganglia_host = 'aggregator1.pmtpa.wmflabs'
        $ganglia_port = 50090
    }

    # else Kafka cluster is based on $::site.
    else {
        $cluster = {
            'eqiad'   => {
                'analytics1021.eqiad.wmnet' => { 'id' => 21 },
                'analytics1022.eqiad.wmnet' => { 'id' => 22 },
            },
            # 'ulsfo' => { },
            # 'pmtpa' => { },
            # 'esams' => { },
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
        $ganglia_host = '239.192.1.32'
        $ganglia_port = 8649
    }

    $brokers          = $cluster[$kafka_cluster_name]
    $zookeeper_hosts  = $role::analytics::zookeeper::config::hosts_array
    $zookeeper_chroot = "/kafka/${kafka_cluster_name}"
    $zookeeper_url    = inline_template("<%= zookeeper_hosts.sort.join(',') %><%= zookeeper_chroot %>")

    $metrics_properties = {
        'kafka.metrics.reporters'                => 'com.criteo.kafka.KafkaGangliaMetricsReporter',
        'kafka.ganglia.metrics.reporter.enabled' =>  'true',
        'kafka.ganglia.metrics.host'             => $ganglia_host,
        'kafka.ganglia.metrics.port'             => $ganglia_port,
        'kafka.ganglia.metrics.group'            => 'kafka',
        'kafka.ganglia.metrics.exclude.regex'    => '^("kafka\.cluster".*)|("kafka\.log".*)|("kafka\.network".*)|("kafka\.server":name="ReplicaFetcherThread.*ConsumerLag.*)$'
    }
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
        content => inline_template("# NOTE:  This file is managed by Puppet\nexport ZOOKEEPER_URL='$zookeeper_url'\n"),
    }
}

# == Class role::analytics::kafka::server
#
class role::analytics::kafka::server inherits role::analytics::kafka::client {
    class { '::kafka::server':
        log_dirs            => $log_dirs,
        brokers             => $brokers,
        zookeeper_hosts     => $zookeeper_hosts,
        zookeeper_chroot    => $zookeeper_chroot,
        metrics_properties  => $metrics_properties,
    }
}
