# == Class druid::middlemanager
# Configures and runs a Druid MiddleManager.
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
#   Default: 8091
#
# [*druid.worker.capacity*]
#   Maximum number of tasks the middle manager can accept.
#   Default: 3
#
# [*druid.indexer.runner.startPort*]
#   The port that peons begin running on.  Default: 8200.
#   Note that ferm rules will be set up to allow incoming access to
#   this + 900 ports.
#
# [*druid.indexer.runner.javaOpts*]
#   -X Java options to run the peon in its own JVM.
#   Note that this default sets Dhadoop.mapreduce.job.user.classpath.first=true.
#   This is a work around for a CDH vs Druid Jackson dependency issue.
#   See: https://github.com/druid-io/druid/pull/2815
#   Default: '-server -Xmx128m -XX:+UseG1GC -XX:MaxGCPauseMillis=100 -Duser.timezone=UTC -Dfile.encoding=UTF-8 -Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager -Dhadoop.mapreduce.job.user.classpath.first=true'
#
# [*druid.indexer.runner.javaCommand*]
#  Path to the Java executable that will be used to launch indexer Peon tasks.
#  Default: $::druid::java_home/bin/java
#
# [*druid.indexer.task.baseTaskDir*]
#   Base temporary working directory for tasks.
#   Default: /var/lib/druid/task
#
# [*druid.server.http.numThreads*]
#   Number of threads for HTTP requests. Default:  4,
#
# [*druid.processing.buffer.sizeBytes*]
#   Default: 134217728
#
# [*druid.processing.numThreads*]
#   Default: 1
#
class druid::middlemanager(
    $properties       = {},
    $env              = {},
    $should_subscribe = false,
)
{
    require ::druid

    $default_properties = {
        'druid.port'                        => 8091,
        'druid.worker.capacity'             => 3,

        'druid.indexer.runner.startPort'    => 8200,
        # Indexer tasks processes (peons) need to run
        # with the same java that druid should use.
        'druid.indexer.runner.javaCommand'  => "${::druid::java_home}/bin/java",
        'druid.indexer.runner.javaOpts'     => '-server -Xmx128m -XX:+UseG1GC -XX:MaxGCPauseMillis=100 -Duser.timezone=UTC -Dfile.encoding=UTF-8 -Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager -Dhadoop.mapreduce.job.user.classpath.first=true',

        'druid.indexer.task.baseTaskDir'    => '/var/lib/druid/task',

        'druid.server.http.numThreads'      => 4,

        'druid.processing.buffer.sizeBytes' => 64000000,

    }

    $default_env = {
        'JAVA_HOME'       => $::druid::java_home,
        'JMX_PORT'        => 9664,
        'DRUID_HEAP_OPTS' => '-Xmx64m -Xms64m',
    }

    # Save these in variables so the properties can be referenced
    # from outside of this class.
    $runtime_properties = merge($default_properties, $properties)
    $environment        = merge($default_env, $env)

    druid::service { 'middlemanager':
        runtime_properties => $runtime_properties,
        env                => $environment,
        should_subscribe   => $should_subscribe,
    }
}
