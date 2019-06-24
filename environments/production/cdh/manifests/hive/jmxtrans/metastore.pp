# == Class cdh::hive::jmxtrans::metastore
# Sets up a jmxtrans instance for the Hive Metastore
# running on the current host.
# Note: This requires the jmxtrans puppet module found at
# https://github.com/wikimedia/puppet-jmxtrans.
#
# == Parameters
# $jmx_port      - DataNode JMX port.  Default: 9981
# $ganglia       - Ganglia host:port
# $graphite      - Graphite host:port
# $statsd        - statsd host:port
# $outfile       - outfile to which Kafka stats will be written.
# $objects       - objects parameter to pass to jmxtrans::metrics.  Only use
#                  this if you need to override the default ones that this
#                  class provides.
#
class cdh::hive::jmxtrans::metastore(
    $jmx_port       = 9979,
    $ganglia        = undef,
    $graphite       = undef,
    $statsd         = undef,
    $outfile        = undef,
    $objects        = undef,
) {
    $jmx = "${::fqdn}:${jmx_port}"
    $group_name = 'Hive.Metastore'

    # query for metrics from Hadoop DataNode's JVM
    jmxtrans::metrics::jvm { 'hadoop-hive-metastore':
        jmx          => $jmx,
        group_prefix => "${group_name}.",
        outfile      => $outfile,
        ganglia      => $ganglia,
        graphite     => $graphite,
        statsd       => $statsd,
    }


    $metastore_objects = $objects ? {
        # if $objects was not set, then use this as the
        # default set of JMX MBean objects to query.
        undef   => [
            {
                'name' =>          'Hive:name=JvmMetrics,service=Metastore',
                'resultAlias'   => "${group_name}.JvmMetrics",
                'attrs'         => {
                    'GcCount'                                   => { 'slope' => 'positive' },
                    'GcCountPS MarkSweep'                       => { 'slope' => 'positive' },
                    'GcCountPS Scavenge'                        => { 'slope' => 'positive' },
                    'GcTimeMillis'                              => { 'slope' => 'both' },
                    'GcTimeMillisPS MarkSweep'                  => { 'slope' => 'both' },
                    'GcTimeMillisPS Scavenge'                   => { 'slope' => 'both' },
                    'LogError'                                  => { 'slope' => 'positive' },
                    'LogFatal'                                  => { 'slope' => 'positive' },
                    'LogInfo'                                   => { 'slope' => 'both' },
                    'LogWarn'                                   => { 'slope' => 'positive' },
                    'MemHeapCommittedM'                         => { 'slope' => 'both' },
                    'MemHeapUsedM'                              => { 'slope' => 'both' },
                    'MemNonHeapCommittedM'                      => { 'slope' => 'both' },
                    'MemNonHeapUsedM'                           => { 'slope' => 'both' },
                    'ThreadsBlocked'                            => { 'slope' => 'both' },
                    'ThreadsNew'                                => { 'slope' => 'both' },
                    'ThreadsRunnable'                           => { 'slope' => 'both' },
                    'ThreadsTerminated'                         => { 'slope' => 'both' },
                    'ThreadsTimedWaiting'                       => { 'slope' => 'both' },
                    'ThreadsWaiting'                            => { 'slope' => 'both' },
                },
            },
        ],
        # else use $objects
        default => $objects,
    }

    # query for jmx metrics
    jmxtrans::metrics { "hadoop-hive-metastore-${::hostname}-${jmx_port}":
        jmx                  => $jmx,
        outfile              => $outfile,
        ganglia              => $ganglia,
        ganglia_group_name   => $group_name,
        graphite             => $graphite,
        graphite_root_prefix => $group_name,
        statsd               => $statsd,
        statsd_root_prefix   => $group_name,
        objects              => $metastore_objects,
    }
}