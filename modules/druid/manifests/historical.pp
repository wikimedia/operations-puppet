# == Class druid::historical
# Configures and runs a Druid Historical Node.
# http://druid.io/docs/latest/design/historical.html
#
# == Parameters
#
# [*properties*]
#   Hash of runtime.properties
#   See: Default $properties
#
# [*env*]
#   Hash of shell environment variables.
#   Default: {
#       'JMX_PORT'             => 9663,
#       'DRUID_HEAP_OPTS'      => '-Xmx256m -Xms256m',
#       'DRUID_EXTRA_JVM_OPTS' => '-XX:MaxDirectMemorySize=256m',
#   }
#
# [*should_subscribe*]
#   True if the service should refresh if any of its config files change.
#   Default: false
#
# === Default $properties
#
# The properties listed here are only the defaults.
# For a full list of configuration properties, see
# http://druid.io/docs/latest/configuration/historical.html
#
# [*druid.port*]
#   Default: 8083
#
# [*druid.server.http.numThreads*]
#   Number of threads for HTTP requests. Default: 4
#
# [*druid.processing.buffer.sizeBytes*]
#   This specifies a buffer size for the storage of intermediate results. The
#   computation engine in both the Historical and Realtime nodes will use a
#   scratch buffer of this size to do all of their intermediate computations
#   off-heap. Larger values allow for more aggregations in a single pass over
#   the data while smaller values can require more passes depending on the
#   query that is being executed. Default: 134217728,
#
# [*druid.processing.numThreads*]
#   The number of processing threads to have available for parallel processing
#   of segments. Default: 1
#
# [*druid.segmentCache.locations*]
#   Segments assigned to a Historical node are first stored on the local file
#   system (in a disk cache) and then served by the Historical node. These
#   locations define where that local cache resides.
#   Default: '[{"path":"/var/lib/druid/segment-cache","maxSize"\:2147483648}]'
#
# [*druid.server.maxSize*]
#   The maximum number of bytes-worth of segments that the node wants assigned
#   to it. This is not a limit that Historical nodes actually enforces, just a
#   value published to the Coordinator node so it can plan accordingly.
#   Default: 2147483648,
#
class druid::historical(
    $properties       = {},
    $env              = {},
    $should_subscribe = false,
)
{
    require ::druid

    $default_properties = {
        'druid.port'                        => 8083,
        # HTTP server threads
        'druid.server.http.numThreads'      => 4,

        # Processing threads and buffers
        'druid.processing.buffer.sizeBytes' => 134217728,
        'druid.processing.numThreads'       => 1,

        # Segment storage
        'druid.segmentCache.locations'      => '[{"path":"/var/lib/druid/segment-cache","maxSize"\:2147483648}]',
        'druid.server.maxSize'              => 2147483648,
    }

    $default_env = {
        'JMX_PORT'             => 9663,
        'DRUID_HEAP_OPTS'      => '-Xmx256m -Xms256m',
        'DRUID_EXTRA_JVM_OPTS' => '-XX:MaxDirectMemorySize=256m',
    }

    # Save these in variables so the properties can be referenced
    # from outside of this class.
    $runtime_properties = merge($default_properties, $properties)
    $environment        = merge($default_env, $env)

    druid::service { 'historical':
        runtime_properties => $runtime_properties,
        env                => $environment,
        should_subscribe   => $should_subscribe,
    }
}
