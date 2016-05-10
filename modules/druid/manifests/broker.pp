# == Class druid::broker
#

# [*druid.service*]

#   Default: druid/broker
# [*druid.port*]

#   Default: 8082

# HTTP server threads
# [*druid.broker.http.numConnections*]

#   Default: 4
# [*druid.server.http.numThreads*]

#   Default: 4

# Processing threads and buffers
# [*druid.processing.buffer.sizeBytes*]

#   Default: 134217728
# [*druid.processing.numThreads*]

#   Default: 1

# Query cache (we use a small local cache)
# [*druid.broker.cache.useCache*]

#   Default: true
# [*druid.broker.cache.populateCache*]

#   Default: true
# [*druid.cache.type*]

#   Default: local
# [*druid.cache.sizeInBytes*]

#   Default: 10000000
class druid::broker(
    $properties = {},
    $env        = {},
)
{
    require druid

    $default_properties = {
        'druid.port'                        => 8082,
        # HTTP server threads,
        'druid.broker.http.numConnections'  => '4',
        'druid.server.http.numThreads'      => '4',
        # Processing threads and buffers,
        'druid.processing.buffer.sizeBytes' => '134217728',
        'druid.processing.numThreads'       => '1',
        # Query cache (we use a small local cache),
        'druid.broker.cache.useCache'       => 'true',
        'druid.broker.cache.populateCache'  => 'true',
        'druid.cache.type'                  => 'local',
        'druid.cache.sizeInBytes'           => '10000000'
    }

    $default_env = {
        'JMX_PORT'             => 9661,
        'DRUID_HEAP_OPTS'      => '-Xmx256m -Xms256m',
        'DRUID_EXTRA_JVM_OPTS' => '-XX:MaxDirectMemorySize=256m',
    }

    druid::service { 'broker':
        runtime_properties => merge($default_properties, $properties),
        env                => merge($default_env, $env),
    }
}
