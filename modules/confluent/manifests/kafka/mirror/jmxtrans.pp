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
    $graphite       = undef,
    $statsd         = undef,
    $outfile        = undef,
    $group_prefix   = undef,
    $objects        = undef,
    $run_interval   = 15,
    $log_level      = 'info',
)
{
    $jmx = "${::fqdn}:${jmx_port}"

    # query for metrics from Kafka's JVM
    jmxtrans::metrics::jvm { $jmx:
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

    $kafka_rate_and_timing_jmx_attrs = merge(
        $kafka_rate_jmx_attrs,
        $kafka_timing_jmx_attrs
    )

    $kafka_value_jmx_attrs = {
        'Value'             => { 'slope' => 'both',     'bucketType' => 'g' },
    }

    $kafka_objects = $objects ? {
        # if $objects was not set, then use this as the
        # default set of Kafka JMX MBean objects to query.
        undef   => [
            #
            # Consumer Metrics
            #
            # TODO: These will likely change if/when we switch to using new java consumer
            # client in MirrorMaker.  (Either when we upgrade, or use --new.consumer flag).
            #

            # ConsumerFetcherManager (MaxLag, MinFetchRate)
            {
                'name'          => 'kafka.consumer:type=ConsumerFetcherManager,name=*,clientId=*',
                'resultAlias'   => 'kafka.consumer.ConsumerFetcherManager',
                'typeNames'     => ['name', 'clientId'],
                'attrs'         => $kafka_value_jmx_attrs,
            },

            # All Topic Consumer Metrics
            {
                'name'          => 'kafka.consumer:type=ConsumerTopicMetrics,name=*,clientId=*',
                'resultAlias'   => 'kafka.consumer.ConsumerTopicMetrics-AllTopics',
                'typeNames'     => ['name', 'clientId'],
                'attrs'         => $kafka_rate_jmx_attrs,
            },
            # Per Topic Consumer Metrics: BytesPerSec, MesagesPerSec
            {
                'name'          => 'kafka.consumer:type=ConsumerTopicMetrics,name=*,clientId=*,topic=*',
                'resultAlias'   => 'kafka.consumer.ConsumerTopicMetrics',
                'typeNames'     => ['name', 'topic', 'clientId'],
                'attrs'         => $kafka_rate_jmx_attrs,
            },
            # Overall Consumer Fetch Request and Response Metrics:
            # FetchRequestRateAndTimeMs, FetchRequestThrottleRateAndTimeMs, FetchResponseSize
            {
                'name'          => 'kafka.consumer:type=FetchRequestAndResponseMetrics,name=FetchRequestRateAndTimeMs,clientId=*',
                'resultAlias'   => 'kafka.consumer.FetchRequestAndResponseMetrics.FetchRequestRateAndTimeMs',
                'typeNames'     => ['clientId'],
                'attrs'         => $kafka_rate_and_timing_jmx_attrs,
            },
            {
                'name'          => 'kafka.consumer:type=FetchRequestAndResponseMetrics,name=FetchRequestThrottleRateAndTimeMs,clientId=*',
                'resultAlias'   => 'kafka.consumer.FetchRequestAndResponseMetrics.FetchRequestThrottleRateAndTimeMs',
                'typeNames'     => ['clientId'],
                'attrs'         => $kafka_rate_and_timing_jmx_attrs,
            },
            {
                'name'          => 'kafka.consumer:type=FetchRequestAndResponseMetrics,name=FetchResponseSize,clientId=*',
                'resultAlias'   => 'kafka.consumer.FetchRequestAndResponseMetrics.FetchResponseSize',
                'typeNames'     => ['clientId'],
                'attrs'         => $kafka_timing_jmx_attrs,
            },

            # Per Broker Fetch Request and Response Metrics:
            # FetchRequestRateAndTimeMs, FetchRequestThrottleRateAndTimeMs, FetchResponseSize
            {
                'name'          => 'kafka.consumer:type=FetchRequestAndResponseMetrics,name=FetchRequestRateAndTimeMs,clientId=*,brokerHost=*,brokerPort=*',
                'resultAlias'   => 'kafka.consumer.FetchRequestAndResponseMetrics.FetchRequestRateAndTimeMs',
                'typeNames'     => ['brokerHost', 'brokerPort', 'clientId'],
                'attrs'         => $kafka_rate_and_timing_jmx_attrs,
            },
            {
                'name'          => 'kafka.consumer:type=FetchRequestAndResponseMetrics,name=FetchRequestThrottleRateAndTimeMs,clientId=*,brokerHost=*,brokerPort=*',
                'resultAlias'   => 'kafka.consumer.FetchRequestAndResponseMetrics.FetchRequestThrottleRateAndTimeMs',
                'typeNames'     => ['brokerHost', 'brokerPort', 'clientId'],
                'attrs'         => $kafka_rate_and_timing_jmx_attrs,
            },
            {
                'name'          => 'kafka.consumer:type=FetchRequestAndResponseMetrics,name=FetchResponseSize,clientId=*,brokerHost=*,brokerPort=*',
                'resultAlias'   => 'kafka.consumer.FetchRequestAndResponseMetrics.FetchResponseSize',
                'typeNames'     => ['brokerHost', 'brokerPort', 'clientId'],
                'attrs'         => $kafka_timing_jmx_attrs,
            },

            # Consumer Lag
            {
                'name'          => 'kafka.server:type=FetcherLagMetrics,name=ConsumerLag,clientId=*,topic=*,partition=*',
                'resultAlias'   => 'kafka.server.FetcherLagMetrics.ConsumerLag',
                'typeNames'     => ['topic', 'partition', 'clientId'],
                'attrs'         => $kafka_value_jmx_attrs,
            },
            # Fetcher Stats: BytesPerSec, RequestsPerSec
            {
                'name'          => 'kafka.server:type=FetcherStats,name=*,clientId=*,brokerHost=*,brokerPort=*',
                'resultAlias'   => 'kafka.server.FetcherStats',
                'typeNames'     => ['name', 'brokerHost', 'brokerPort', 'clientId'],
                'attrs'         => $kafka_rate_jmx_attrs,
            },

            # Commit Metrics:
            # KafkaCommitsPerSec (new consumer), ZooKeeperCommitsPerSec (old consumer)
            {
                'name'          => 'kafka.consumer:type=ZookeeperConsumerConnector,name=KafkaCommitsPerSec,clientId=*',
                'resultAlias'   => 'kafka.consumer.ZookeeperConsumerConnector.KafkaCommitsPerSec',
                'typeNames'     => ['clientId'],
                'attrs'         => $kafka_rate_jmx_attrs,
            },
            {
                'name'          => 'kafka.consumer:type=ZookeeperConsumerConnector,name=ZooKeeperCommitsPerSec,clientId=*',
                'resultAlias'   => 'kafka.consumer.ZookeeperConsumerConnector.ZooKeeperCommitsPerSec',
                'typeNames'     => ['clientId'],
                'attrs'         => $kafka_rate_jmx_attrs,
            },
            # Owned Partition Count (global, not per topic)
            {
                'name'          => 'kafka.consumer:type=ZookeeperConsumerConnector,name=OwnedPartitionsCount,clientId=*,groupId=*',
                'resultAlias'   => 'kafka.consumer.ZookeeperConsumerConnector.OwnedPartitionsCount',
                'typeNames'     => ['groupId', 'clientId'],
                'attrs'         => $kafka_value_jmx_attrs,
            },
            # Rebalance Stats
            {
                'name'          => 'kafka.consumer:type=ZookeeperConsumerConnector,name=RebalanceRateAndTime,clientId=*',
                'resultAlias'   => 'kafka.consumer.ZookeeperConsumerConnector.RebalanceRateAndTime',
                'typeNames'     => ['clientId'],
                'attrs'         => $kafka_rate_and_timing_jmx_attrs,
            },

            #
            # Producer Metrics
            #

            # All Topic Producer Metrics
            {
                'name'          => 'kafka.producer:type=producer-metrics,client-id=*',
                'resultAlias'   => 'kafka.producer.producer-metrics',
                'typeNames'     => ['client-id'],
                'attrs'         => {
                    'metadata-age'              => { 'slope' => 'both', 'bucketType' => 'g' },

                    'batch-size-avg'            => { 'slope' => 'both', 'bucketType' => 'g' },
                    'batch-size-max'            => { 'slope' => 'both', 'bucketType' => 'g' },

                    'buffer-available-bytes'    => { 'slope' => 'both', 'bucketType' => 'g' },
                    'buffer-exhausted-rate'     => { 'slope' => 'both', 'bucketType' => 'g' },
                    'buffer-total-bytes'        => { 'slope' => 'both', 'bucketType' => 'g' },
                    'bufferpool-wait-ratio'     => { 'slope' => 'both', 'bucketType' => 'g' },

                    'compression-rate-avg'      => { 'slope' => 'both', 'bucketType' => 'g' },

                    'connection-close-rate'     => { 'slope' => 'both', 'bucketType' => 'g' },
                    'connection-count'          => { 'slope' => 'both', 'bucketType' => 'g' },
                    'connection-creation-rate'  => { 'slope' => 'both', 'bucketType' => 'g' },

                    'incoming-byte-rate'        => { 'slope' => 'both', 'bucketType' => 'g' },
                    'outgoing-byte-rate'        => { 'slope' => 'both', 'bucketType' => 'g' },

                    'io-ratio'                  => { 'slope' => 'both', 'bucketType' => 'g' },
                    'io-time-ns-avg'            => { 'slope' => 'both', 'bucketType' => 'g' },
                    'io-wait-ratio'             => { 'slope' => 'both', 'bucketType' => 'g' },
                    'io-wait-time-ns-avg'       => { 'slope' => 'both', 'bucketType' => 'g' },
                    'network-io-rate'           => { 'slope' => 'both', 'bucketType' => 'g' },

                    'produce-throttle-time-avg' => { 'slope' => 'both', 'bucketType' => 'g' },
                    'produce-throttle-time-max' => { 'slope' => 'both', 'bucketType' => 'g' },

                    'record-error-rate'         => { 'slope' => 'both', 'bucketType' => 'g' },
                    'record-queue-time-avg'     => { 'slope' => 'both', 'bucketType' => 'g' },
                    'record-queue-time-max'     => { 'slope' => 'both', 'bucketType' => 'g' },
                    'record-retry-rate'         => { 'slope' => 'both', 'bucketType' => 'g' },
                    'record-send-rate'          => { 'slope' => 'both', 'bucketType' => 'g' },
                    'record-size-avg'           => { 'slope' => 'both', 'bucketType' => 'g' },
                    'record-size-max'           => { 'slope' => 'both', 'bucketType' => 'g' },
                    'records-per-request-avg'   => { 'slope' => 'both', 'bucketType' => 'g' },

                    'request-latency-avg'       => { 'slope' => 'both', 'bucketType' => 'g' },
                    'request-latency-max'       => { 'slope' => 'both', 'bucketType' => 'g' },
                    'request-rate'              => { 'slope' => 'both', 'bucketType' => 'g' },
                    'request-size-avg'          => { 'slope' => 'both', 'bucketType' => 'g' },
                    'request-size-max'          => { 'slope' => 'both', 'bucketType' => 'g' },
                    'requests-in-flight'        => { 'slope' => 'both', 'bucketType' => 'g' },

                    'response-rate'             => { 'slope' => 'both', 'bucketType' => 'g' },

                    'select-rate'               => { 'slope' => 'both', 'bucketType' => 'g' },
                    'waiting-threads'           => { 'slope' => 'both', 'bucketType' => 'g' },
                }
            },

            # Per Topic Producer Metrics
            {
                'name'          => 'kafka.producer:type=producer-topic-metrics,client-id=*,topic=*',
                'resultAlias'   => 'kafka.producer.producer-topic-metrics',
                'typeNames'     => ['topic', 'client-id'],
                'attrs'         => {
                    'byte-rate'                 => { 'slope' => 'both', 'bucketType' => 'g' },
                    'compression-rate'          => { 'slope' => 'both', 'bucketType' => 'g' },
                    'record-error-rate'         => { 'slope' => 'both', 'bucketType' => 'g' },
                    'record-retry-rate'         => { 'slope' => 'both', 'bucketType' => 'g' },
                    'record-send-rate'          => { 'slope' => 'both', 'bucketType' => 'g' },
                }
            },

            # Per Producer Node (to a specific broker) Metrics
            {
                'name'          => 'kafka.producer:type=producer-node-metrics,client-id=*,node-id=*',
                'resultAlias'   => 'kafka.producer.producer-node-metrics',
                'typeNames'     => ['node-id', 'client-id'],
                'attrs'         => {
                    'incoming-byte-rate'        => { 'slope' => 'both', 'bucketType' => 'g' },
                    'outgoing-byte-rate'        => { 'slope' => 'both', 'bucketType' => 'g' },
                    'request-latency-avg'       => { 'slope' => 'both', 'bucketType' => 'g' },
                    'request-latency-max'       => { 'slope' => 'both', 'bucketType' => 'g' },
                    'request-rate'              => { 'slope' => 'both', 'bucketType' => 'g' },
                    'request-size-avg'          => { 'slope' => 'both', 'bucketType' => 'g' },
                    'request-size-max'          => { 'slope' => 'both', 'bucketType' => 'g' },
                    'response-rate'             => { 'slope' => 'both', 'bucketType' => 'g' },
                }
            },

        ],
        default => $objects,
    }

    # query kafka for jmx metrics
    jmxtrans::metrics { "kafka-mirror-${title}-${jmx_port}":
        jmx                  => $jmx,
        outfile              => $outfile,
        graphite             => $graphite,
        graphite_root_prefix => "${group_prefix}kafka-mirror",
        statsd               => $statsd,
        statsd_root_prefix   => "${group_prefix}kafka-mirror",
        objects              => $kafka_objects,
    }
}
