# == Class druid::coordinator
# Configures and runs a Druid Coordinator.
# http://druid.io/docs/latest/design/coordinator.html
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
#       'JMX_PORT'             => 9662,
#       'DRUID_HEAP_OPTS'      => '-Xmx128m -Xms128m',
#       'DRUID_EXTRA_JVM_OPTS' => '-Dderby.stream.error.file=/var/log/druid/coordinator-derby.log',
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
# http://druid.io/docs/latest/configuration/coordinator.html
#
# [*druid.port*]
#   Default: 8081
#
# [*druid.coordinator.startDelay*]
#   The operation of the Coordinator works on the assumption that it has an
#   up-to-date view of the state of the world when it runs.  The current ZK
#   interaction code, however, is written in a way that doesn't allow the
#   Coordinator to know for a fact that it's done loading the current state of
#   the world. This delay is a hack to give it enough time to believe that it
#   has all the data. Default: PT30S
#
# [*druid.coordinator.period*]
#   The run period for the coordinator. The coordinator's operates by
#   maintaining the current state of the world in memory and periodically
#   looking at the set of segments available and segments being served to make
#   decisions about whether any changes need to be made to the data topology.
#   This property sets the delay between each of these runs. Default: PT30S
#
class druid::coordinator(
    $properties       = {},
    $env              = {},
    $should_subscribe = false,
)
{
    require ::druid

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

    # Save these in variables so the properties can be referenced
    # from outside of this class.
    $runtime_properties = merge($default_properties, $properties)
    $environment        = merge($default_env, $env)

    druid::service { 'coordinator':
        runtime_properties => $runtime_properties,
        env                => $environment,
        should_subscribe   => $should_subscribe,
    }
}
