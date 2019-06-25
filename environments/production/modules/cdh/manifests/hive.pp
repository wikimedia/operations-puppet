# == Class cdh::hive
#
# Installs Hive packages (needed for Hive Client).
# Use this in conjunction with cdh::hive::master to install and set up a
# Hive Server and Hive Metastore.
# This also installs hive-hcatalog
#
# == Parameters
# $metastore_host                - fqdn of the metastore host
# $zookeeper_hosts               - Array of zookeeper hostname/IP(:port)s.
#                                  Default: undef (zookeeper lock management
#                                  will not be used).
#
# $support_concurrency           - Whether Hive supports concurrency or not. A Zookeeper
#                                  instance must be up and running for the default Hive
#                                  lock manager to support read-write locks.
#                                  Default: false
#
# $jdbc_database                 - Metastore JDBC database name.
#                                  Default: 'hive_metastore'
# $jdbc_username                 - Metastore JDBC username.  Default: hive
# $jdbc_password                 - Metastore JDBC password.  Default: hive
# $jdbc_host                     - Metastore JDBC hostname.  Default: localhost
# $jdbc_port                     - Metastore JDBC port.      Default: 3306
# $jdbc_driver                   - Metastore JDBC driver class name.
#                                  Default: org.apache.derby.jdbc.EmbeddedDriver
# $jdbc_protocol                 - Metastore JDBC protocol.  Default: mysql
#
#                                  Only set these if your root user cannot issue database
#                                  commands without a different username and password.
#                                  Default: undef
# $variable_substitute_depth     - The maximum replacements the substitution engine will do. Default: undef
#
# $auxpath                       - Additional path to pass to hive.  Default: undef
# $parquet_compression           - Compression type for parquet-format to use.  It will
#                                  ignore mapreduce_output_compession_codec.  Set this to
#                                  one of UNCOMPRESSED, SNAPPY, GZIP.  Default: undef
# $exec_parallel_thread_number   - Number of jobs at most can be executed in parallel.
#                                  Set this to 0 to disable parallel execution.
# $optimize_skewjoin             - Enable or disable skew join optimization.
#                                  Default: false
# $skewjoin_key                  - Number of rows where skew join is used.
#                                - Default: 10000
# $skewjoin_mapjoin_map_tasks    - Number of map tasks used in the follow up
#                                  map join jobfor a skew join.   Default: 10000.
# $skewjoin_mapjoin_min_split    - Skew join minimum split size.  Default: 33554432
#
# $stats_enabled                 - Enable or disable temp Hive stats.  Default: false
# $stats_dbclass                 - The default database class that stores
#                                  temporary hive statistics.  Default: jdbc:derby
# $stats_jdbcdriver              - JDBC driver for the database that stores
#                                  temporary hive statistics.
#                                  Default: org.apache.derby.jdbc.EmbeddedDriver
# $stats_dbconnectionstring      - Connection string for the database that stores
#                                  temporary hive statistics.
#                                  Default: jdbc:derby:;databaseName=TempStatsStore;create=true
# $hive_metastore_sasl_enabled                     - If true, the metastore thrift interface will be secured with SASL.
#                                                    Clients must authenticate with Kerberos. Default: undef
# $hive_metastore_kerberos_keytab_file             - The path to the Kerberos Keytab file containing the metastore
#                                                    thrift server's service principal.</description>
# $hive_metastore_kerberos_principal               - The service principal for the metastore thrift server.
#                                                    The special string _HOST will be replaced automatically with
#                                                    the correct host name.
# $hive_server2_authentication                     - This property sets the authentication mode for Hive Server 2.
#                                                    Values available: NOSASL, KERBEROS, NONE, PLAINTEXT. Default: undef
# $hive_server2_authentication_kerberos_principal  - The service principal for the Hive Server. Default: undef
# $hive_server2_authentication_kerberos_keytab     - The path to the Kerberos Keytab file.
# $config_files_group_ownership                    - The file group ownership of Hive's configuration files like hive-site.xml.
#                                                    When running jobs in Hadoop is desirable not to run them under users like 'hdfs'
#                                                    but with lower priviledged ones. These jobs needs, most of the times, to read
#                                                    files like hive-site.xml, so proper group permissions are needed.
#                                                    Default: 'hdfs'
#
class cdh::hive(
    $metastore_host,
    $zookeeper_hosts             = undef,
    $support_concurrency         = false,
    $jdbc_database               = 'hive_metastore',
    $jdbc_username               = 'hive',
    $jdbc_password               = 'hive',
    $jdbc_host                   = 'localhost',
    $jdbc_port                   = 3306,
    $jdbc_driver                 = 'com.mysql.jdbc.Driver',
    $jdbc_protocol               = 'mysql',

    $variable_substitute_depth   = undef,
    $auxpath                     = undef,
    $parquet_compression         = undef,

    $exec_parallel_thread_number = 8,
    $optimize_skewjoin           = false,
    $skewjoin_key                = 10000,
    $skewjoin_mapjoin_map_tasks  = 10000,
    $skewjoin_mapjoin_min_split  = 33554432,

    $stats_enabled               = false,
    $stats_dbclass               = 'jdbc:derby',
    $stats_jdbcdriver            = 'org.apache.derby.jdbc.EmbeddedDriver',
    $stats_dbconnectionstring    = 'jdbc:derby:;databaseName=TempStatsStore;create=true',

    $hive_site_template          = 'cdh/hive/hive-site.xml.erb',
    $hive_log4j_template         = 'cdh/hive/hive-log4j.properties.erb',
    $java_logging_template       = 'cdh/hive/java-logging.properties.erb',
    $hive_exec_log4j_template    = 'cdh/hive/hive-exec-log4j.properties.erb',
    $hive_env_template           = 'cdh/hive/hive-env.sh.erb',

    $java_home                   = undef,

    $hive_metastore_opts         = '-Xmx2048m',
    $hive_server_opts            = '-Xmx2048m',
    $hive_metastore_jmx_port     = 9979,
    $hive_server_jmx_port        = 9978,

    $hive_server_udf_blacklist   = undef,

    $hive_metastore_sasl_enabled = undef,
    $hive_metastore_kerberos_keytab_file = undef,
    $hive_metastore_kerberos_principal   = undef,

    $hive_server2_authentication = undef,
    $hive_server2_authentication_kerberos_principal = undef,
    $hive_server2_authentication_kerberos_keytab    = undef,

    $config_files_group_ownership = 'hdfs',

) {
    Class['cdh::hadoop'] -> Class['cdh::hive']

    package { 'hive':
        ensure => 'installed',
    }

    # Explicitly adding the 'hive' user
    # to the catalog, even if created by the hive package,
    # to allow other resources to require it.
    user { 'hive':
        gid        => 'hive',
        comment    => 'Hive User',
        home       => '/var/lib/hive',
        shell      => '/bin/false',
        managehome => false,
        system     => true,
        require    => Package['hive'],
    }

    # https://issues.apache.org/jira/browse/HIVE-12582
    # Introduce the HIVE_SERVER2_HADOOP_OPTS environment variable
    # to allow a fine tuning of JVM's parameters. Not yet included in
    # upstream's Hive or related distributions.
    file { '/usr/lib/hive/bin/ext/hiveserver2.sh':
        source  => 'puppet:///modules/cdh/hive/hiveserver2.sh',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => Package['hive'],
    }

    $config_directory = "/etc/hive/conf.${cdh::hadoop::cluster_name}"
    # Create the $cluster_name based $config_directory.
    file { $config_directory:
        ensure  => 'directory',
        require => Package['hive'],
    }
    cdh::alternative { 'hive-conf':
        link => '/etc/hive/conf',
        path => $config_directory,
    }

    # If we need more hcatalog services
    # (e.g. webhcat), this may be moved
    # to a class of its own.
    package { 'hive-hcatalog':
        ensure  => 'installed',
        require => Package['hive'],
    }

    # Make sure hive-site.xml is not world readable on the
    # metastore host.  On the metastore host, hive-site.xml
    # will contain database connection credentials.
    $hive_site_mode = $metastore_host ? {
        $::fqdn => '0440',
        default => '0444',
    }
    # variable needed to generate hive-env.sh.erb template
    $java_logging_config_file = "${config_directory}/java-logging.properties"
    file { "${config_directory}/hive-env.sh":
        content => template($hive_env_template),
        mode    => '0444',
        owner   => 'root',
        group   => 'hdfs',
        require => Package['hive'],
    }
    file { "${config_directory}/hive-site.xml":
        content => template($hive_site_template),
        mode    => $hive_site_mode,
        owner   => 'hive',
        group   => $config_files_group_ownership,
        require => Package['hive'],
    }
    file { "${config_directory}/hive-log4j.properties":
        content => template($hive_log4j_template),
        require => Package['hive'],
    }
    file { $java_logging_config_file:
        content => template($java_logging_template),
        require => Package['hive'],
    }
    file { "${config_directory}/hive-exec-log4j.properties":
        content => template($hive_exec_log4j_template),
        require => Package['hive'],
    }
}
