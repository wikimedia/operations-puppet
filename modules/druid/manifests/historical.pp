# == Class druid::historical
#
class druid::historical(
    $properties = {},
    $env        = {},
)
{
    require druid

    $default_properties = {
        'druid.port'                        => 8083,
        # HTTP server threads
        'druid.server.http.numThreads'      => 4,

        # Processing threads and buffers
        'druid.processing.buffer.sizeBytes' => 134217728,
        'druid.processing.numThreads'       => 1,

        # Segment storage
        'druid.segmentCache.locations'      => '[{"path":"var/lib/druid/segment-cache","maxSize"\:2147483648}]',
        'druid.server.maxSize'              => 2147483648,
    }

    $default_env = {
        'JMX_PORT'             => 9663,
        'DRUID_HEAP_OPTS'      => '-Xmx256m -Xms256m',
        'DRUID_EXTRA_JVM_OPTS' => '-XX:MaxDirectMemorySize=256m',
    }

    druid::service { 'historical':
        runtime_properties => merge($default_properties, $properties),
        env                => merge($default_env, $env),
    }
}
