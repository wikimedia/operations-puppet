# == Class druid::overlord
# Configures and runs a Druid Overlord.
# http://druid.io/docs/latest/design/indexing-service.html
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
#       'JMX_PORT'             => 9664,
#       'DRUID_HEAP_OPTS'      => '-Xmx64m -Xms64m',
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
# http://druid.io/docs/latest/configuration/indexing-service.html
#
# [*druid.port*]
#   Default: 8090
#
# [*druid.indexer.queue.startDelay*]
#   Sleep this long before starting overlord queue management. This can be
#   useful to give a cluster time to re-orient itself after e.g. a widespread
#   network issue. Default: PT5S
#
# [*druid.indexer.runner.type*]
#   Choices "local" or "remote". Indicates whether tasks should be run locally
#   or in a distributed environment.  Default: 'remote'
#
# [*druid.indexer.storage.type*]
#   Choices are "local" or "metadata". Indicates whether incoming tasks should
#   be stored locally (in heap) or in metadata storage. Storing incoming tasks
#   in metadata storage allows for tasks to be resumed if the overlord should
#   fail. Default: 'metadata'
#
class druid::overlord(
    $properties       = {},
    $env              = {},
    $should_subscribe = false,
)
{
    require ::druid

    $default_properties = {
        'druid.port'                     => 8090,
        'druid.indexer.queue.startDelay' => 'PT5S',

        'druid.indexer.runner.type'      => 'remote',
        'druid.indexer.storage.type'     => 'metadata',
    }

    $default_env = {
        'JMX_PORT'        => 9665,
        'DRUID_HEAP_OPTS' => '-Xmx128m -Xms128m',
    }


    # Save these in variables so the properties can be referenced
    # from outside of this class.
    $runtime_properties = merge($default_properties, $properties)
    $environment        = merge($default_env, $env)

    druid::service { 'overlord':
        runtime_properties => $runtime_properties,
        env                => $environment,
        should_subscribe   => $should_subscribe,
    }
}
