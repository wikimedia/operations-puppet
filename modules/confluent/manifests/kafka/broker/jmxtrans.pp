# == Class confluent::kafka::broker::jmxtrans
# Sets up a jmxtrans instance for a 0.8.2+ Kafka Broker
# running on the current host.
# Note: This requires the jmxtrans puppet module found at
# https://github.com/wikimedia/puppet-jmxtrans.
#
# == Parameters
# [*graphite*]
#   Graphite host:port. Default: under
#
# [*statsd*]
#   statsd host:port. Default: under
#
# [*outfile*]
#   outfile to which Kafka stats will be written. Default: under
#
# [*objects*]
#   objects parameter to pass to jmxtrans::metrics.  Only use
#   this if you need to override the default ones that this class provides.
#   Default: undef
#
# [*group_prefix]
#   If set, this will be prefixed to all metrics.  Default: undef
#
# [*run_interval*]
#   How often jmxtrans should run in seconds.  Default: 15
#
# [*log_level*]
#   Level at which jmxtrans should log.   Default: info
#
# == Usage
# class { '::confluent::kafka::broker::jmxtrans':
#     group_prefix => 'kafka.cluster.example',
#     statsd       => hiera('statsd', undef),
# }
#
class confluent::kafka::broker::jmxtrans(
    $graphite       = undef,
    $statsd         = undef,
    $outfile        = undef,
    $group_prefix   = undef,
    $objects        = undef,
    $run_interval   = 15,
    $log_level      = 'info',
    $ensure         = 'present',
)
{
    require ::confluent::kafka::broker

    $jmx_port = $::confluent::kafka::broker::jmx_port
    $jmx = "${::fqdn}:${jmx_port}"

    if !defined(Class['::jmxtrans']) {
        class { '::jmxtrans':
            run_interval => $run_interval,
            log_level    => $log_level,
        }
    }

    if !defined(Nrpe::Monitor_service['jmxtrans']) {
        # Generate icinga alert if this jmxtrans instance is not running.
        nrpe::monitor_service { 'jmxtrans':
            ensure       => $ensure,
            description  => 'jmxtrans',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java --ereg-argument-array "-jar.+jmxtrans-all.jar"',
            require      => Class['::jmxtrans'],
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Kafka',
        }
    }

    # query for metrics from Kafka's JVM
    jmxtrans::metrics::jvm { $jmx:
        ensure       => $ensure,
        graphite     => $graphite,
        statsd       => $statsd,
        outfile      => $outfile,
        group_prefix => $group_prefix,
    }

    # DRY up some often used JMX attributes.
    $kafka_rate_jmx_attrs = {
        'Count'             => { 'slope' => 'positive', 'bucketType' => 'g' },
        'FifteenMinuteRate' => { 'slope' => 'both',     'bucketType' => 'g' },
        'FiveMinuteRate'    => { 'slope' => 'both',     'bucketType' => 'g' },
        'OneMinuteRate'     => { 'slope' => 'both',     'bucketType' => 'g' },
        'MeanRate'          => { 'slope' => 'both',     'bucketType' => 'g' },
    }
    $kafka_timing_jmx_attrs = {
        '50thPercentile'     => { 'slope' => 'both',     'bucketType' => 'g' },
        '75ththPercentile'   => { 'slope' => 'both',     'bucketType' => 'g' },
        '95thPercentile'     => { 'slope' => 'both',     'bucketType' => 'g' },
        '98thPercentile'     => { 'slope' => 'both',     'bucketType' => 'g' },
        '99thPercentile'     => { 'slope' => 'both',     'bucketType' => 'g' },
        '999thPercentile'    => { 'slope' => 'both',     'bucketType' => 'g' },
        'Count'              => { 'slope' => 'positive', 'bucketType' => 'g' },
        'Max'                => { 'slope' => 'both',     'bucketType' => 'g' },
        'Mean'               => { 'slope' => 'both',     'bucketType' => 'g' },
        'Min'                => { 'slope' => 'both',     'bucketType' => 'g' },
        'StdDev'             => { 'slope' => 'both',     'bucketType' => 'g' },
    }
    $kafka_value_jmx_attrs = {
        'Value'             => { 'slope' => 'both',     'bucketType' => 'g' },
    }

    $kafka_objects = $objects ? {
        # if $objects was not set, then use this as the
        # default set of Kafka JMX MBean objects to query.
        undef   => [
            # All Topic Metrics
            {
                'name'          => 'kafka.server:type=BrokerTopicMetrics,name=*',
                'resultAlias'   => 'kafka.server.BrokerTopicMetrics-AllTopics',
                'typeNames'     => ['name'],
                'attrs'         => $kafka_rate_jmx_attrs,
            },
            # Per Topic Metrics
            # These are listed separately so that that each name.topic
            # can be keyed individually.  If you used ['name', 'topic']
            # as typeNames, the keys would be like
            # kafka.server.BrokerTopicMetrics.BytesInPerSec_webrequest_text.OneMinuteRate
            # Instead of kafka.server.BrokerTopicMetrics.BytesInPerSec.webrequest_text.OneMinuteRate
            {
                'name'          => 'kafka.server:type=BrokerTopicMetrics,name=BytesInPerSec,topic=*',
                'resultAlias'   => 'kafka.server.BrokerTopicMetrics.BytesInPerSec',
                'typeNames'     => ['topic'],
                'attrs'         => $kafka_rate_jmx_attrs,
            },
            {
                'name'          => 'kafka.server:type=BrokerTopicMetrics,name=BytesOutPerSec,topic=*',
                'resultAlias'   => 'kafka.server.BrokerTopicMetrics.BytesOutPerSec',
                'typeNames'     => ['topic'],
                'attrs'         => $kafka_rate_jmx_attrs,
            },
            {
                'name'          => 'kafka.network:type=BrokerTopicMetrics,name=BytesRejectedPerSec,topic=*',
                'resultAlias'   => 'kafka.network.BrokerTopicMetrics.BytesRejectedPerSec',
                'typeNames'     => ['topic'],
                'attrs'         => $kafka_rate_jmx_attrs,
            },
            {
                'name'          => 'kafka.network:type=BrokerTopicMetrics,name=FailedFetchRequestsPerSec,topic=*',
                'resultAlias'   => 'kafka.network.BrokerTopicMetrics.FailedFetchRequestsPerSec',
                'typeNames'     => ['topic'],
                'attrs'         => $kafka_rate_jmx_attrs,
            },
            {
                'name'          => 'kafka.network:type=BrokerTopicMetrics,name=FailedProduceRequestsPerSec,topic=*',
                'resultAlias'   => 'kafka.network.BrokerTopicMetrics.FailedProduceRequestsPerSec',
                'typeNames'     => ['topic'],
                'attrs'         => $kafka_rate_jmx_attrs,
            },
            {
                'name'          => 'kafka.server:type=BrokerTopicMetrics,name=MessagesInPerSec,topic=*',
                'resultAlias'   => 'kafka.server.BrokerTopicMetrics.MessagesInPerSec',
                'typeNames'     => ['topic'],
                'attrs'         => $kafka_rate_jmx_attrs,
            },

            # ReplicaManager Metrics
            # These are listed separately because they don't all share the
            # same attributes.
            {
                'name'          => 'kafka.server:type=ReplicaManager,name=IsrExpandsPerSec',
                'resultAlias'   => 'kafka.server.ReplicaManager.IsrExpandsPerSec',
                'attrs'         => $kafka_rate_jmx_attrs,
            },
            {
                'name'          => 'kafka.server:type=ReplicaManager,name=IsrShrinksPerSec',
                'resultAlias'   => 'kafka.server.ReplicaManager.IsrShrinksPerSec',
                'attrs'         => $kafka_rate_jmx_attrs,
            },                {
                'name'          => 'kafka.server:type=ReplicaManager,name=LeaderCount',
                'resultAlias'   => 'kafka.server.ReplicaManager.LeaderCount',
                'attrs'         => $kafka_value_jmx_attrs,
            },                {
                'name'          => 'kafka.server:type=ReplicaManager,name=PartitionCount',
                'resultAlias'   => 'kafka.server.ReplicaManager.PartitionCount',
                'attrs'         => $kafka_value_jmx_attrs,
            },                {
                'name'          => 'kafka.server:type=ReplicaManager,name=UnderReplicatedPartitions',
                'resultAlias'   => 'kafka.server.ReplicaManager.UnderReplicatedPartitions',
                'attrs'         => $kafka_value_jmx_attrs,
            },

            # ReplicaFetcherManager
            {
                'name'          => 'kafka.server:type=ReplicaFetcherManager,name=*,clientId=Replica',
                'resultAlias'   => 'kafka.server.ReplicaFetcherManager',
                'typeNames'     => ['name'],
                'attrs'         => $kafka_value_jmx_attrs,
            },

            # Producer/Fetch Request Purgatory Metrics
            {
                'name'          => 'kafka.server:type=ProducerRequestPurgatory,name=*',
                'resultAlias'   => 'kafka.server.ProducerRequestPurgatory',
                'typeNames'     => ['name'],
                'attrs'         => $kafka_value_jmx_attrs,
            },
            {
                'name'          => 'kafka.server:type=FetchRequestPurgatory,name=*',
                'resultAlias'   => 'kafka.server.FetchRequestPurgatory',
                'typeNames'     => ['name'],
                'attrs'         => $kafka_value_jmx_attrs,
            },

            # Request Handler Percent Idle
            {
                'name'          => 'kafka.server:type=KafkaRequestHandlerPool,name=*',
                'resultAlias'   => 'kafka.server.KafkaRequestHandlerPool',
                'typeNames'     => ['name'],
                'attrs'         => $kafka_rate_jmx_attrs,
            },


            # Request Metrics

            # Requests Type Metrics
            {
                'name'          => 'kafka.network:type=RequestMetrics,name=RequestsPerSec,request=*',
                'resultAlias'   => 'kafka.network.RequestMetrics.RequestsPerSec',
                'typeNames'     => ['request'],
                'attrs'         => $kafka_rate_jmx_attrs,
            },
            # Request/Response Local Time Metrics
            {
                'name'          => 'kafka.network:type=RequestMetrics,name=LocalTimeMs,request=*',
                'resultAlias'   => 'kafka.network.RequestMetrics.LocalTimeMs',
                'typeNames'     => ['request'],
                'attrs'         => $kafka_timing_jmx_attrs,
            },
            # Request/Response Remote Time Metrics
            {
                'name'          => 'kafka.network:type=RequestMetrics,name=RemoteTimeMs,request=*',
                'resultAlias'   => 'kafka.network.RequestMetrics.RemoteTimeMs',
                'typeNames'     => ['request'],
                'attrs'         => $kafka_timing_jmx_attrs,
            },
            # Request Queue Time Metrics
            {
                'name'          => 'kafka.network:type=RequestMetrics,name=RequestQueueTimeMs,request=*',
                'resultAlias'   => 'kafka.network.RequestMetrics.RequestQueueTimeMs',
                'typeNames'     => ['request'],
                'attrs'         => $kafka_timing_jmx_attrs,
            },
            # Response Queue Time Metrics
            {
                'name'          => 'kafka.network:type=RequestMetrics,name=ResponseQueueTimeMs,request=*',
                'resultAlias'   => 'kafka.network.RequestMetrics.ResponseQueueTimeMs',
                'typeNames'     => ['request'],
                'attrs'         => $kafka_timing_jmx_attrs,
            },
            # Response Send Time Metrics
            {
                'name'          => 'kafka.network:type=RequestMetrics,name=ResponseSendTimeMs,request=*',
                'resultAlias'   => 'kafka.network.RequestMetrics.ResponseSendTimeMs',
                'typeNames'     => ['request'],
                'attrs'         => $kafka_timing_jmx_attrs,
            },
            # Request/Response Total Time Metrics
            {
                'name'          => 'kafka.network:type=RequestMetrics,name=TotalTimeMs,request=*',
                'resultAlias'   => 'kafka.network.RequestMetrics.TotalTimeMs',
                'typeNames'     => ['request'],
                'attrs'         => $kafka_timing_jmx_attrs,
            },

            # Log Flush Metrics
            {
                'name'          => 'kafka.log:type=LogFlushStats,name=*',
                'resultAlias'   => 'kafka.log.Log.LogFlushStats',
                'typeNames'     => ['name'],
                'attrs'         => merge($kafka_timing_jmx_attrs, $kafka_rate_jmx_attrs),
            },

            # Per topic-partition Metrics
            {
                'name'          => 'kafka.log:type=Log,name=LogStartOffset,topic=*,partition=*',
                'resultAlias'   => 'kafka.log.Log.LogStartOffset',
                'typeNames'     => ['topic', 'partition'],
                'attrs'         => $kafka_value_jmx_attrs,
            },
            {
                'name'          => 'kafka.log:type=Log,name=LogEndOffset,topic=*,partition=*',
                'resultAlias'   => 'kafka.log.Log.LogEndOffset',
                'typeNames'     => ['topic', 'partition'],
                'attrs'         => $kafka_value_jmx_attrs,
            },
            {
                'name'          => 'kafka.log:type=Log,name=Size,topic=*,partition=*',
                'resultAlias'   => 'kafka.log.Log.Size',
                'typeNames'     => ['topic', 'partition'],
                'attrs'         => $kafka_value_jmx_attrs,
            },


            # Controller Info
            {
                'name'          => 'kafka.controller:type=KafkaController,name=*',
                'resultAlias'   => 'kafka.controller.KafkaController',
                'typeNames'     => ['name'],
                'attrs'         => $kafka_value_jmx_attrs,
            },
            # Controller Metrics
            {
                'name'          => 'kafka.controller:type=ControllerStats,name=*',
                'resultAlias'   => 'kafka.controller.ControllerStats',
                'typeNames'     => ['name'],
                'attrs'         => merge($kafka_timing_jmx_attrs, $kafka_rate_jmx_attrs),
            },

            # Per topic-partition UnderReplicated Partition Metrics
            # TODO: fix this metric.  It should work!
            {
                'name'          => 'kafka.cluster:type=Partition,name=UnderReplicated,topic=*,partition=*',
                'resultAlias'   => 'kafka.cluster.Partition.UnderReplicated',
                'typeNames'     => ['topic, partition'],
                'attrs'         => $kafka_value_jmx_attrs,
            },

            # Per topic-partitions replica lag
            # TODO: fix this metric.  It should work!
            {
                'name'          => 'kafka.server:type=FetcherLagMetrics,name=ConsumerLag,clientId=*,topic=*,partition=*',
                'resultAlias'   => 'kafka.server.FetcherLagMetrics.ConsumerLag',
                'typeNames'     => ['clientId', 'topic, partition'],
                'attrs'         => $kafka_value_jmx_attrs,
            },
        ],
        default => $objects,
    }


    # Query kafka for jmx metrics.
    jmxtrans::metrics { "kafka-${::hostname}-${jmx_port}":
        ensure               => $ensure,
        jmx                  => $jmx,
        outfile              => $outfile,
        graphite             => $graphite,
        graphite_root_prefix => "${group_prefix}kafka",
        statsd               => $statsd,
        statsd_root_prefix   => "${group_prefix}kafka",
        objects              => $kafka_objects,
    }
}
