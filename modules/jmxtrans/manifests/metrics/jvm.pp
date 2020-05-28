# == Define jmxtrans::metrics::jvm
#
# Sets up this JVM to be monitored by a jmxtrans node.
# Note that at present this only really does the right thing with CMS and
# Parallel GC.
#
# == Parameters
# $jmx            - host:port of JMX to query.  Default: $title
# $graphite       - $graphite parameter to pass to jmxtrans::metrics
# $statsd         - host:port of statsd server      Optional.
# $outfile        - $outfile parameter to pass to jmxtrans::metrics
# $group_prefix   - Prefix string to prepend to graphite_root_prefix.  Default: ''
#
define jmxtrans::metrics::jvm(
    $jmx          = $title,
    $graphite     = undef,
    $statsd       = undef,
    $outfile      = undef,
    $group_prefix = '',
    $ensure       = 'present',
)
{
    jmxtrans::metrics { "${title}-jvm-metrics":
        # lint:ignore:arrow_alignment
        ensure               => $ensure,
        jmx                  => $jmx,
        outfile              => $outfile,
        graphite             => $graphite,
        graphite_root_prefix => "${group_prefix}jvm_memory",
        statsd               => $statsd,
        statsd_root_prefix   => "${group_prefix}jvm_memory",
        objects              => [
            {
                'name'        => 'java.lang:type=Memory',
                'resultAlias' => 'memory',
                'attrs'       => {
                    'HeapMemoryUsage'    => {'units' => 'bytes', 'slope' => 'both'},
                    'NonHeapMemoryUsage' => {'units' => 'bytes', 'slope' => 'both'},
                }
            },
            # Garbage Collector metrics
            {
                'name'         => 'java.lang:name=*,type=GarbageCollector',
                'typeNames'    => ['name'],
                'result_alias' => 'GarbageCollector',
                'attrs'        => {
                    'CollectionCount' => {'units' => 'GCs', 'slope' => 'both'},
                    'CollectionTime'  => {'units' => 'milliseconds', 'slope' => 'positive'},
                }
            },
            # These only show up for Java 7
            {
                'name'        => 'java.nio:name=mapped,type=BufferPool',
                'resultAlias' => 'buffer_pool_mapped',
                'attrs'       => {
                    'MemoryUsed' => {'units' => 'bytes', 'slope' => 'both'},
                    'Count'      => {'units' => 'buffers', 'slope' => 'both'},
                }
            },
            {
                'name'        => 'java.nio:name=direct,type=BufferPool',
                'resultAlias' => 'buffer_pool_direct',
                'attrs'       => {
                    'MemoryUsed' => {'units' => 'bytes', 'slope' => 'both'},
                    'Count'      => {'units' => 'buffers', 'slope' => 'both'},
                }
            }
        # lint:endignore
        ]
    }
}
