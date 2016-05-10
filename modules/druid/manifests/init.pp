# == Class druid
#
# Installs druid-common and configures common runtime properties.
#
# == Parameters
#
# [*properties*]
#   Hash of runtime.properties
#   See: Default $properties
#
# === Default $properties
#
# The properties listed here are only the defaults.
# For a full list of configuration properties, see
# http://druid.io/docs/latest/configuration/coordinator.html
#
#
#
# [*druid.extensions.directory*]
#   Druid extensions are installed here.  Only extensions listed in
#   druid.extensions.loadList will be automatically loaded into the classpath.
#   Default: /usr/share/druid/extensions
#
# [*druid.extensions.loadList*]
#   List extensions to load.  Directories matching these names must exist
#   in druid.extensions.directory.
#   Default: ["druid-histogram", "druid-datasketches", "druid-namespace-lookup"]
#
# [*druid.extensions.hadoopDependenciesDir*]
#   If you have a different version of Hadoop, place your Hadoop client jar
#   files in your hadoop-dependencies directory and uncomment the line below to
#   point to your directory.  Or you may manually include them in
#   DRUID_CLASSPATH.
#   Default: /usr/share/druid/hadoop-dependencies
#
# [*druid.startup.logging.logProperties*]
#   Log all runtime properties on startup. Disable to avoid logging properties
#   on startup. Default: true
#
# [*druid.zk.service.host*]
#   Zookeeper hostnames. Default: localhost:2181
#
# [*druid.zk.paths.base*]
#   Chroot to druid in zookeeper. Default: /druid
#
# [*druid.metadata.storage.type*]
#   For Derby server on your Druid Coordinator (only viable in a cluster with
#   single Coordinator, no fail-over).  Default: derby
#
# [*druid.metadata.storage.connector.connectURI*]
#   Default: jdbc:derby://localhost:1527/var/lib/druid/metadata.db;create=true
#
# [*druid.metadata.storage.connector.host*]
#   Default: localhost
#
# [*druid.metadata.storage.connector.port*]
#   Default: 1527
#
# [*druid.storage.type*]
#   Default: noop
#
# [*druid.indexer.logs.type*]
#   This property must be set for both overlord and middlemanager, hence
#   it is present in common.runtime.properties.
#   Default: file
#
# [*druid.indexer.logs.directory*]
#   This property must be set for both overlord and middlemanager, hence
#   it is present in common.runtime.properties.
#   Default: /var/lib/druid/indexing-logs
#
# [*druid.monitoring.monitors*]
#   Default: ["com.metamx.metrics.JvmMonitor"]
#
# [*druid.emitter*]
#   Default: logging
#
# [*druid.emitter.logging.logLevel*]
#   Default: info
#
class druid(
    $properties = {},
)
{
    $default_properties = {
        'druid.extensions.directory'                        => '/usr/share/druid/extensions',
        'druid.extensions.loadList'                         => [
            'druid-histogram',
            'druid-datasketches',
            'druid-namespace-lookup'
        ],
        'druid.extensions.hadoopDependenciesDir'            => '/usr/share/druid/hadoop-dependencies',
        'druid.startup.logging.logProperties'               => true,
        'druid.zk.service.host'                             => 'localhost:2181',
        'druid.zk.paths.base'                               => '/druid',
        'druid.metadata.storage.type'                       => 'derby',
        'druid.metadata.storage.connector.connectURI'       => 'jdbc:derby://localhost:1527/var/lib/druid/metadata.db;create=true',
        'druid.metadata.storage.connector.host'             => 'localhost',
        'druid.metadata.storage.connector.port'             => 1527,
        'druid.storage.type'                                => 'noop',
        'druid.monitoring.monitors'                         => ['com.metamx.metrics.JvmMonitor'],
        'druid.emitter'                                     => 'logging',
        'druid.emitter.logging.logLevel'                    => 'info'
    }
    $runtime_properties = merge($default_properties, $properties)

    require_package('druid-common')

    file { '/etc/druid/common.runtime.properties':
        content => template('druid/runtime.properties.erb')
    }
}
