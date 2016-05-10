# == Class druid::overlord
#
class druid::overlord(
    $properties = {},
    $env        = {},
)
{
    require druid

    $default_properties = {
        'druid.port'                     => 8090,
        'druid.indexer.queue.startDelay' => 'PT5S',

        'druid.indexer.runner.type'      => 'remote',
        'druid.indexer.storage.type'     => 'metadata',
    }

    $default_env = {
        'JMX_PORT'             => 9665,
        'DRUID_HEAP_OPTS'      => '-Xmx128m -Xms128m',
    }

    druid::service { 'overlord':
        runtime_properties => merge($default_properties, $properties),
        env                => merge($default_env, $env),
    }
}
