# == Class confluent::kafka::mirror::jmxtrans
#
# Sets up a jmxtrans instance for a Kafka MirrorMaker instance
# running on the current host.
# Note: This requires the jmxtrans puppet module found at
# https://github.com/wikimedia/puppet-jmxtrans.
#
# == Parameters
#
# [*title*]
#   Should be the same as the kafka::mirror instance you want to monitor.
#
# [*jmx_port*]
#   Kafka MirrorMaker JMX port
#
# [*ganglia*]
#   Ganglia host:port
#
# [*graphite*]
#   Graphite host:port
#
# [*statsd*]
#   statsd host:port
#
# [*outfile*]
#   outfile to which Kafka stats will be written.
#
# [*objects*]
#   objects parameter to pass to jmxtrans::metrics.  Only use this if you need
#   to override the default ones that this class provides.
#
# [*group_prefix*]
#   If set, this will be prefixed to all metrics.  Default: undef
#
# [*run_interval*]
#   How often jmxtrans should run.  Default: 15 seconds
#
# [*log_level*]
#   level at which jmxtrans should log.   Default: info
#
# == Usage
# confluent::kafka::mirror::jmxtrans { 'main_to_aggregate':
#     statsd => 'statsd.example.org:8125'
# }
#
define confluent::kafka::mirror::jmxtrans(
    $jmx_port       = 9997,
    $ganglia        = undef,
    $graphite       = undef,
    $statsd         = undef,
    $outfile        = undef,
    $group_prefix   = undef,
    $objects        = undef,
    $run_interval   = 15,
    $log_level      = 'info',
)
{
    # NOTE: $title should match title of confluent::kafka::mirror::instance
    # instance (AKA $mirror_name).
    $client_id = "kafka-mirror-${title}"
    $jmx = "${::fqdn}:${jmx_port}"

    # query for metrics from Kafka's JVM
    jmxtrans::metrics::jvm { $jmx:
        ganglia      => $ganglia,
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
            #
            # DataChannel Metrics
            #
            {
                'name'          => 'kafka.tools:type=DataChannel,name=MirrorMaker-DataChannel-Size',
                'resultAlias'   => 'kafka.tools.MirrorMaker.DataChannel.Size',
                'attrs'         => $kafka_timing_jmx_attrs,
            },
            {
                'name'          => 'kafka.tools:type=DataChannel,name=MirrorMaker-DataChannel-WaitOnPut',
                'resultAlias'   => 'kafka.tools.MirrorMaker.DataChannel.WaitOnPut',
                'attrs'         => $kafka_rate_jmx_attrs,
            },
            {
                'name'          => 'kafka.tools:type=DataChannel,name=MirrorMaker-DataChannel-WaitOnTake',
                'resultAlias'   => 'kafka.tools.MirrorMaker.DataChannel.WaitOnTake',
                'attrs'         => $kafka_rate_jmx_attrs,
            },

            #
            # Consumer Metrics
            #

            # ConsumerFetcheManager (MaxLag, MinFetchRate)
            {
                'name'          => "kafka.consumer:type=ConsumerFetcherManager,name=*,clientId=${client_id}",
                'resultAlias'   => 'kafka.consumer.ConsumerFetcherManager',
                'typeNames'     => ['name'],
                'attrs'         => $kafka_value_jmx_attrs,
            },

            # All Topic Consumer Metrics
            {
                'name'          => "kafka.consumer:type=ConsumerTopicMetrics,name=*,clientId=${client_id}",
                'resultAlias'   => 'kafka.consumer.ConsumerTopicMetrics-AllTopics',
                'typeNames'     => ['name'],
                'attrs'         => $kafka_rate_jmx_attrs,
            },
            # Per Topic Consumer Metrics
            {
                'name'          => "kafka.consumer:type=ConsumerTopicMetrics,name=BytesPerSec,clientId=${client_id},topic=*",
                'resultAlias'   => 'kafka.consumer.ConsumerTopicMetrics.BytesPerSec',
                'typeNames'     => ['topic'],
                'attrs'         => $kafka_rate_jmx_attrs,
            },
            {
                'name'          => "kafka.consumer:type=ConsumerTopicMetrics,name=MessagesPerSec,clientId=${client_id},topic=*",
                'resultAlias'   => 'kafka.consumer.ConsumerTopicMetrics.MessagesPerSec',
                'typeNames'     => ['topic'],
                'attrs'         => $kafka_rate_jmx_attrs,
            },

            # Overall Consumer Fetch Request and Response Metrics
            {
                'name'          => "kafka.consumer:type=FetchRequestAndResponseMetrics,name=*,clientId=${client_id}",
                'resultAlias'   => 'kafka.consumer.FetchRequestAndResponseMetrics',
                'typeNames'     => ['name'],
                'attrs'         => $kafka_timing_jmx_attrs,
            },
            # Per Broker Fetch Request and Response Metrics
            {
                'name'          => "kafka.consumer:type=FetchRequestAndResponseMetrics,name=FetchRequestRateAndTimeMs,clientId=${client_id},brokerHost=*,brokerPort=*",
                'resultAlias'   => 'kafka.consumer.FetchRequestAndResponseMetrics.FetchRequestRateAndTimeMs',
                'typeNames'     => ['brokerHost', 'brokerPort'],
                'attrs'         => $kafka_timing_jmx_attrs,
            },
            {
                'name'          => "kafka.consumer:type=FetchRequestAndResponseMetrics,name=FetchResponseSize,clientId=${client_id},brokerHost=*,brokerPort=*",
                'resultAlias'   => 'kafka.consumer.FetchRequestAndResponseMetrics.FetchResponseSize',
                'attrs'         => $kafka_timing_jmx_attrs,
                'attrs'         => $kafka_timing_jmx_attrs,
            },

            # Consumer Lag
            {
                'name'          => "kafka.server:type=FetcherLagMetrics,name=ConsumerLag,clientId=${client_id},topic=*,partition=*",
                'resultAlias'   => 'kafka.server.FetcherLagMetrics.ConsumerLag',
                'typeNames'     => ['topic', 'partition'],
                'attrs'         => $kafka_value_jmx_attrs,
            },
            # Fetcher Stats
            {
                'name'          => "kafka.server:type=FetcherStats,name=BytesPerSec,clientId=${client_id},brokerHost=*,brokerPort=*",
                'resultAlias'   => 'kafka.server.FetcherStats.BytesPerSec',
                'typeNames'     => ['brokerHost', 'brokerPort'],
                'attrs'         => $kafka_rate_jmx_attrs,
            },
            {
                'name'          => "kafka.server:type=FetcherStats,name=RequestsPerSec,clientId=${client_id},brokerHost=*,brokerPort=*",
                'resultAlias'   => 'kafka.server.FetcherStats.RequestsPerSec',
                'typeNames'     => ['brokerHost', 'brokerPort'],
                'attrs'         => $kafka_rate_jmx_attrs,
            },

            # Commit Metrics
            {
                'name'          => "kafka.consumer:type=ZookeeperConsumerConnector,name=KafkaCommitsPerSec,clientId=${client_id}",
                'resultAlias'   => 'kafka.consumer.ZookeeperConsumerConnector.KafkaCommitsPerSec',
                'attrs'         => $kafka_rate_jmx_attrs,
            },
            {
                'name'          => "kafka.consumer:type=ZookeeperConsumerConnector,name=ZooKeeperCommitsPerSec,clientId=${client_id}",
                'resultAlias'   => 'kafka.consumer.ZookeeperConsumerConnector.ZooKeeperCommitsPerSec',
                'attrs'         => $kafka_rate_jmx_attrs,
            },


            #
            # Producer Topic Metrics
            #

            # Producer client.ids are suffixed with the producer number.
            # This means that we can't clean up the resultAlias well for
            # producer metrics.

            # All Topic Producer Metrics
            {
                'name'          => 'kafka.producer:type=ProducerTopicMetrics,name=BytesPerSec,clientId=*',
                'resultAlias'   => 'kafka.producer.ProducerTopicMetrics-AllTopics.BytesPerSec',
                'typeNames'     => ['clientId'],
                'attrs'         => $kafka_rate_jmx_attrs,
            },
            {
                'name'          => 'kafka.producer:type=ProducerTopicMetrics,name=DroppedMessagesPerSec,clientId=*',
                'resultAlias'   => 'kafka.producer.ProducerTopicMetrics-AllTopics.DroppedMessagesPerSec',
                'typeNames'     => ['clientId'],
                'attrs'         => $kafka_rate_jmx_attrs,
            },
            {
                'name'          => 'kafka.producer:type=ProducerTopicMetrics,name=MessagesPerSec,clientId=*',
                'resultAlias'   => 'kafka.producer.ProducerTopicMetrics-AllTopics.MessagesPerSec',
                'typeNames'     => ['clientId'],
                'attrs'         => $kafka_rate_jmx_attrs,
            },
            # Per Topic Producer Metrics
            {
                'name'          => 'kafka.producer:type=ProducerTopicMetrics,name=BytesPerSec,clientId=*',
                'resultAlias'   => 'kafka.producer.ProducerTopicMetrics.BytesPerSec',
                'typeNames'     => ['clientId', 'topic'],
                'attrs'         => $kafka_rate_jmx_attrs,
            },
            {
                'name'          => 'kafka.producer:type=ProducerTopicMetrics,name=DroppedMessagesPerSec,clientId=*,topic=*',
                'resultAlias'   => 'kafka.producer.ProducerTopicMetrics.DroppedMessagesPerSec',
                'typeNames'     => ['clientId', 'topic'],
                'attrs'         => $kafka_rate_jmx_attrs,
            },
            {
                'name'          => 'kafka.producer:type=ProducerTopicMetrics,name=MessagesPerSec,clientId=*,topic=*',
                'resultAlias'   => 'kafka.producer.ProducerTopicMetrics.MessagesPerSec',
                'typeNames'     => ['clientId', 'topic'],
                'attrs'         => $kafka_rate_jmx_attrs,
            },

            # Async Producer Metrics
            {
                'name'          => 'kafka.producer.async:type=ProducerSendThread,name=ProducerQueueSize,clientId=*',
                'resultAlias'   => 'kafka.producer.ProducerSendThread.ProducerQueueSize',
                'typeNames'     => ['clientId'],
                'attrs'         => $kafka_value_jmx_attrs,
            },
        ],
        default => $objects,
    }

    # query kafka for jmx metrics
    jmxtrans::metrics { "kafka-mirror-${client_id}-${jmx_port}":
        jmx                  => $jmx,
        outfile              => $outfile,
        ganglia              => $ganglia,
        ganglia_group_name   => "${group_prefix}kafka-mirror",
        graphite             => $graphite,
        graphite_root_prefix => "${group_prefix}kafka-mirror",
        statsd               => $statsd,
        statsd_root_prefix   => "${group_prefix}kafka-mirror",
        objects              => $kafka_objects,
    }
}
