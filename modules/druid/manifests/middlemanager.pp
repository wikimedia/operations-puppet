# == Class druid::middlemanager
#
class druid::middlemanager(
    $properties = {},
    $env        = {},
)
{
    require druid

    $default_properties = {
        'druid.port'                        => 8091,
        # Number of tasks per middleManager
        'druid.worker.capacity'             => 3,

        # Task launch parameters
        'druid.indexer.runner.javaOpts'     => '-server -Xmx128m -Duser.timezone=UTC -Dfile.encoding=UTF-8 -Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager',
        'druid.indexer.task.baseTaskDir'    => '/var/lib/druid/task',

        # HTTP server threads
        'druid.server.http.numThreads'      => 4,

        # Processing threads and buffers
        'druid.processing.buffer.sizeBytes' => 134217728,
        'druid.processing.numThreads'       => 1,
    }

    $default_env = {
        'JMX_PORT'             => 9664,
        'DRUID_HEAP_OPTS'      => '-Xmx64m -Xms64m',
    }

    druid::service { 'middlemanager':
        runtime_properties => merge($default_properties, $properties),
        env                => merge($default_env, $env),
    }
}
