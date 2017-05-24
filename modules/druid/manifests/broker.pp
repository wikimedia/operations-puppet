# == Class druid::broker
# Configures and runs a Druid Broker.
# http://druid.io/docs/latest/design/broker.html
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
#       'JMX_PORT'             => 9661,
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
# http://druid.io/docs/latest/configuration/broker.html
#
# [*druid.port*]
#   Default: 8082
#
# [*druid.broker.http.numConnections*]
#   Size of connection pool for the Broker to connect to historical and
#   real-time nodes. If there are more queries than this number that all need
#   to speak to the same node, then they will queue up. Default: 4
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
#   query that is being executed.  Default: 134217728
#
# [*druid.processing.numThreads*]
#   The number of processing threads to have available for parallel processing
#   of segments. Default: 1
#
# [*druid.broker.cache.useCache*]
#   Enable the query cache on the broker.
#   Default: true
#
# [*druid.broker.cache.populateCache*]
#   Populate the query cache on the broker. Default: true
#
# [*druid.cache.type*]
#   The type of cache to use for queries. Default: local
#
# [*druid.cache.sizeInBytes*]
#   Maximum cache size in bytes. Zero disables caching. Default: 10000000
#
class druid::broker(
    $properties       = {},
    $env              = {},
    $should_subscribe = false,
)
{
    require ::druid

    $default_properties = {
        'druid.port'                        => 8082,

        'druid.broker.http.numConnections'  => '4',
        'druid.server.http.numThreads'      => '4',

        'druid.processing.buffer.sizeBytes' => '134217728',
        'druid.processing.numThreads'       => '1',

        'druid.broker.cache.useCache'       => true,
        'druid.broker.cache.populateCache'  => true,
        'druid.cache.type'                  => 'local',
        'druid.cache.sizeInBytes'           => '10000000',
    }

    $default_env = {
        'JMX_PORT'             => 9661,
        'DRUID_HEAP_OPTS'      => '-Xmx256m -Xms256m',
        'DRUID_EXTRA_JVM_OPTS' => '-XX:MaxDirectMemorySize=256m',
    }

    # Save these in variables so the properties can be referenced
    # from outside of this class.
    $runtime_properties = merge($default_properties, $properties)
    $environment        = merge($default_env, $env)

    druid::service { 'broker':
        runtime_properties => $runtime_properties,
        env                => $environment,
        should_subscribe   => $should_subscribe,
    }
}
