# == Class druid
#
# Installs druid-common and configures common runtime properties.
#
# This class tries to set convenient defaults based on provided $properties.
# $properties always directly overrides any of the defaults configured here.
#
#
# === MySQL Metadata Storage Configuration ===
#
# The default druid.metadata.storage.type is 'derby'.  If you set this to
# to 'mysql', this class will configure MySQL defaults for the
# druid.metadata.storage.connector.* properties.  E.g.
#
#   {
#       'druid.metadata.storage.type'          => 'mysql',
#       'druid.metadata.storage.connector.host => 'mysql.server.org',
#   }
#
# By setting storage.type to mysql, the mysql-metadata-storage extension
# will be included by default.  If you need to override any
# of these defaults, you may provide them in $properties directly.
#
# Since the database name is not directly a Druid property, you must
# provide a full druid.metadata.storage.connector.connectURI to override that.
# The default MySQL db name is 'druid'.
#
# NOTE that this class will not create the database or grant user permissions
# for you.  You must do that manually.
# See: http://druid.io/docs/0.9.0/development/extensions-core/mysql.html for
# instructions.
#
# Likely, you will just need to:
#
#   CREATE DATABASE druid DEFAULT CHARACTER SET utf8;
#   GRANT ALL ON druid.* TO 'druid'@'%' IDENTIFIED BY 'druid';
#
#
# === Deep Storage Configuration ===
#
# By default deep storage is disabled.  Set druid.storage.type to
# 'local' to configure local deep storage in /var/lib/druid/deep-storage.
#
# Set druid.storage.type to 'hdfs' to configure HDFS based deep
# storage in /user/druid/deep-storage.  Make sure that a Hadoop client
# is configured on this node, and that the /user/druid/deep-storage
# directory exists.  The druid-hdfs-storage extension will be included by
# default when druid.storage.type is 'hdfs'.
#
#
# == Parameters
#
# [*properties*]
#   Hash of runtime.properties
#   See: Default $properties
#
# [*metadata_storage_database_name*]
#   This will be used as the database name / derby file name
#   of the configured metadata storage.  Default: 'druid'
#
# [*java_home*]
#   Path to JAVA_HOME.  This will be set for all daemon environemnts in their env.sh files.
#   This is done because default Java on Debian (Jessie) systems is Java 7, and Druid 0.10+
#   requires Java 8.
#
# [*use_cdh*]
#   If this is true, the druid::cdh::hadoop::dependencies class
#   will be included, and deep storage will be configured to use
#   a special druid-hdfs-storage-cdh extension.  If you set this,
#   make sure to include the druid::cdh::hadoop::user class on your
#   Hadoop NameNodes.  Default: false.
#
#
# === Default $properties
#
# The properties listed here are only the defaults.
# For a full list of configuration properties, see
# http://druid.io/docs/0.9.0/configuration/index.html
#
# [*druid.extensions.directory*]
#   Druid extensions are installed here.  Only extensions listed in
#   druid.extensions.loadList will be automatically loaded into the classpath.
#   Default: /usr/share/druid/extensions
#
# [*druid.extensions.loadList*]
#   List extensions to load.  Directories matching these names must exist
#   in druid.extensions.directory.
#   Default: [
#       'druid-datasketches',
#       'druid-histogram',
#       'druid-lookups-cached-global'
#       'mysql-metadata-storage', # only if druid.metadata.storage.type == mysql
#       'druid-hdfs-storage',     # only if druid.storage.type == hdfs
#   ],
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
#   Default: local
#
# [*druid.storage.storageDirectory*]
#   Directory to use as deep storage.  Default: /var/lib/druid/deep-storage
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
# [*druid.emitter*]
#   Default: logging
#
# [*druid.emitter.logging.logLevel*]
#   Default: info
#
class druid(
    $properties = {},
    $metadata_storage_database_name = 'druid',
    $java_home  = '/usr/lib/jvm/java-1.8.0-openjdk-amd64',
    $use_cdh    = false,
)
{
    if $use_cdh {
        # Create links to CDH Hadoop Client dependencies.
        include ::druid::cdh::hadoop::dependencies
    }

    # If metadata storage is in MySQL, set some nice defaults.  Note that
    # these can still be overridden by setting them in $properties.
    if $properties['druid.metadata.storage.type'] == 'mysql' {
        $default_metadata_properties = {
            'druid.metadata.storage.type'       => 'mysql',
            'druid.metadata.storage.connector.user'       => 'druid',
            'druid.metadata.storage.connector.password'   => 'druid',
            'druid.metadata.storage.connector.host'       => 'localhost',
            'druid.metadata.storage.connector.port'       => 3306,
            # Let's be nice and set connectURI based on passed in properties, or
            # the defaults here, so things like host and port don't have to be
            # passed in more than once.
            'druid.metadata.storage.connector.connectURI' => inline_template(
                'jdbc:mysql://<%= @properties.fetch("druid.metadata.storage.connector.host", "localhost") %>:<%= @properties.fetch("druid.metadata.storage.connector.port", "3306") %>/<%= @metadata_storage_database_name %>'
            ),
        }
        # Set this variable so it is included in the union
        # for $extensions below.
        $metadata_extensions = ['mysql-metadata-storage']
    }
    # Default to using derby for metadata storage.
    else {
        $default_metadata_properties = {
            'druid.metadata.storage.type'                 => 'derby',
            'druid.metadata.storage.connector.host'       => 'localhost',
            'druid.metadata.storage.connector.port'       => 1527,
            # Let's be nice and set connectURI based on passed in properties, or
            # the defaults here, so things like host and port don't have to be
            # passed in more than once.  Note that you'll have to override
            # this if you want to change the path to the derby database file.
            'druid.metadata.storage.connector.connectURI' => inline_template(
                'jdbc:derby://<%= @properties.fetch("druid.metadata.storage.connector.host", "localhost") %>:<%= @properties.fetch("druid.metadata.storage.connector.port", "1527") %>/var/lib/druid/<%= @metadata_storage_database_name %>_metadata.db;create=true'
            ),
        }
        # No extra metadata extensions needed
        $metadata_extensions         = []
    }

    # If deep storage is HDFS, then default to storing it in
    # /user/druid/deep-storage.  Make sure this diretory exists in HDFS
    # and is writable by druid!  Note that these can still be overridden by
    # setting them in $properties.
    if $properties['druid.storage.type'] == 'hdfs' {

        $default_deep_storage_properties = {
            # If using CDH, make sure these directories exists in HDFS by declaring
            # druid::cdh::hadoop::deep_storage on your Hadoop NameNodes.
            'druid.storage.storageDirectory' => '/user/druid/deep-storage',
        }

        # If using CDH, then use special CDH settings and dependencies.
        if $use_cdh {
            # Load the special druid-hdfs-storage-cdh extension created by
            # the druid::cdh::hadoop::dependencies class.
            $storage_extensions = ['druid-hdfs-storage-cdh']
        }
        # Else just use the hadoop dependencies shipped by the druid package
        else {
            $storage_extensions = ['druid-hdfs-storage']
        }
    }
    # Else use local deep storage defaulting storageDirectory to
    # /var/lib/druid/deep-storage.
    elsif $properties['druid.storage.type'] == 'local' or $properties['druid.storage.type'] == undef {
        $default_deep_storage_properties = {
            'druid.storage.type'             => 'local',
            'druid.storage.storageDirectory' => '/var/lib/druid/deep-storage',
        }
        # No extra storage extensions needed
        $storage_extensions              = []
    }

    $default_extensions = [
        'druid-datasketches',
        'druid-histogram',
        'druid-lookups-cached-global',
    ]
    # Get a unique list of extensions to load built up from
    # the defaults configured here.  Note that if
    # druid.extensions.loadList is set in $properties
    # it will override any of these.
    $extensions = sort(union(
        $default_extensions,
        $metadata_extensions,
        $storage_extensions
    ))

    $default_properties = {
        'druid.indexer.logs.type'                     => 'file',
        'druid.indexer.logs.directory'                => '/var/lib/druid/indexing-logs',
        'druid.extensions.directory'                  => '/usr/share/druid/extensions',
        'druid.extensions.loadList'                   => $extensions,
        'druid.extensions.hadoopDependenciesDir'      => '/usr/share/druid/hadoop-dependencies',
        'druid.startup.logging.logProperties'         => true,
        'druid.zk.service.host'                       => 'localhost:2181',
        'druid.zk.paths.base'                         => '/druid',
        'druid.emitter'                               => 'logging',
        'druid.emitter.logging.logLevel'              => 'info',
    }

    # Finally, make a good list of properties with nice defaults for different
    # metadata and deep storage types, loading extensions appropriately.
    # This will be rendered into common.runtime.properties.
    $runtime_properties = merge(
        $default_properties,
        $default_metadata_properties,
        $default_deep_storage_properties,
        $properties
    )

    require_package('druid-common')

    # Useful to resources that need the druid user to
    # work properly. The user is created by druid-common.
    user { 'druid':
        gid        => 'druid',
        comment    => 'Druid',
        home       => '/nonexistent',
        shell      => '/bin/false',
        managehome => false,
        system     => true,
        require    => Package['druid-common'],
    }

    file { '/etc/druid/common.runtime.properties':
        content => template('druid/runtime.properties.erb'),
    }
}
