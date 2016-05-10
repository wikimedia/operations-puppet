# == Class druid::coordinator
#
class druid::coordinator(
    $properties = {},
    $env        = {},
)
{
    require druid

    $default_properties = {
        'druid.port'                   => 8081,
        'druid.coordinator.startDelay' => 'PT30S',
        'druid.coordinator.period'     => 'PT30S',
    }

    $default_env = {
        'JMX_PORT'             => 9662,
        'DRUID_HEAP_OPTS'      => '-Xmx128m -Xms128m',
        'DRUID_EXTRA_JVM_OPTS' => '-Dderby.stream.error.file=/var/log/druid/coordinator-derby.log',
    }

    druid::service { 'coordinator':
        runtime_properties => merge($default_properties, $properties),
        env                => merge($default_env, $env),
    }
}
