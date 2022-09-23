# SPDX-License-Identifier: Apache-2.0

# == Class profile::hadoop::spark3
# Ultimately this class will install the Spark3 debian package,
# created from a conda environement.
# For now it creates only the spark3 configuration, which is used
# by a Spark3 isntance available through the Airflow installation
# on an-launcher1002
#
# Note: We keep commented the parameters and code from the spark2.pp class
# that we think will be needed when the proper Spark3 package installation
# will be done.
#
# [*install_yarn_shuffle_jar*]
#   TODO: implement
#   If true, any Spark 1 or 2 yarn shuffle jars in /usr/lib/hadoop-yarn/lib
#   will be replaced with the Spark 3 one, causing YARN NodeManagers to run
#   the Spark 3 shuffle service.
#   Default: true
#
# [*install_assembly*]
#   TODO: implement
#   Deploy the spark3-assembly.zip to HDFS if not already present.
#   Set this to true on a single Hadoop client node.
#   Default: false
#
# [*extra_settings*]
#   Map of key value pairs to add to spark3-defaults.conf
#   Default: {}
#
# [*driver_port*]
#   If specified, it will add two settings to the config:
#   - spark.driver.port: $driver_port
#   Works only if spark.port.maxRetries is also specified.
#   Default: 12000
#
# [*driver_blockmanager_port*]
#   If specified, it will add the following to the config:
#   - spark.driver.blockManager.port
#   Works only if spark.port.maxRetries is also specified.
#   Default: 13000
#
# [*ui_port*]
#   If specified, it will add the following to the config:
#   - spark.ui.port
#   Works only if spark.port.maxRetries is also specified.
#   Default: 4040
#
# [*port_max_retries*]
#   If specified, it will add this setting to the config:
#   - spark.port.maxRetries: $port_max_retries
#   This allows the creation of a 100 port range for the driver,
#   and it adds it to the ferm config.
#   Default: 100
#
# [*executor_env_ld_lib_path*]
#   Explicitly set the LD_LIBRARY_PATH of Spark executors to avoid any errors
#   related to missing Hadoop native libraries (like Snappy for example). We already
#   have a similar setting in yarns-site.xml for the Application Master, but having
#   it stated in the Spark3's defaults has been proven in the past to work well
#   (especially when testing Kerberos in the Hadoop Test cluster).
#   Default: /usr/lib/hadoop/lib/native
#
# [*encryption_enabled*]
#   Enable encryption of RPC calls and IO files created by the shuffler.
#   This option is a convenient way to enable the right/suggested set of options
#   on all Spark 3 client/worker node.
#   Default: true
#
# [*local_dir*]
#   This option is used as a default value for the spark.local.dir configuration
#   parameter. It is used for scratch file storage space. If not specified, it will
#   be omitted from the configuration file and the compiled-in default value of /tmp
#   will be used.
#
class profile::hadoop::spark3(
    # Boolean $install_yarn_shuffle_jar          = lookup('profile::hadoop::spark3::install_yarn_shuffle_jar', {'default_value' => true}),
    # Boolean $install_assembly                  = lookup('profile::hadoop::spark3::install_assembly', {'default_value' => false}),
    Hash[String, Any] $extra_settings          = lookup('profile::hadoop::spark3::extra_settings', {'default_value' => {}}),
    Stdlib::Port $driver_port                  = lookup('profile::hadoop::spark3::driver_port', {'default_value' => 12000}),
    Stdlib::Port $driver_blockmanager_port     = lookup('profile::hadoop::spark3::driver_blockmanager_port', {'default_value' => 13000}),
    Stdlib::Port $ui_port                      = lookup('profile::hadoop::spark3::ui_port', {'default_value' => 4040}),
    Integer $port_max_retries                  = lookup('profile::hadoop::spark3::port_max_retries', {'default_value' => 100}),
    Stdlib::Unixpath $executor_env_ld_lib_path = lookup('profile::hadoop::spark3::executor_env_ld_lib_path', {'default_value' => '/usr/lib/hadoop/lib/native'}),
    Boolean $encryption_enabled                = lookup('profile::hadoop::spark3::encryption_enabled', {'default_value' => true}),
    Optional[Stdlib::Unixpath] $local_dir      = lookup('profile::hadoop::spark3::local_dir', {'default_value' => undef })
) {
    require ::profile::hadoop::common

    # We use conda-analytics to distribute spark3,
    # and also want to use it as the default analytics cluster python for spark.
    require ::profile::analytics::conda_analytics

    # $python_prefix_global variable will be rendered into spark-env.sh and used as the default
    # values for PYSPARK_PYTHON and PYSPARK_DRIVER_PYTHON.
    $python_prefix_global = $::conda_analytics::prefix

    # TODO: get spark_version from conda_analytics env and use it to create and upload spark assembly.
    # Get spark_version from facter. Use the default provided via hiera if not set.
    # $spark_version = $::spark_version ? {
    #     undef   => $default_version,
    #     default => $::spark_version
    # }
    # For now, this is used in spark-defaults.conf to set the hardcoded value of spark.yarn.archives.
    # It should match the Spark version encapsulated in the conda-analytics pkg.
    $spark_version = '3.1.2'

    # Ensure that a symlink to hive-site.xml exists so that
    # spark3 will automatically get Hive support.
    if defined(Class['::bigtop::hive']) {
        $hive_enabled = true
        file { '/etc/spark3/conf/hive-site.xml':
            ensure => 'link',
            target => "${::bigtop::hive::config_directory}/hive-site.xml",
        }
    }
    else {
        $hive_enabled = false
    }

    # Set Spark spark.sql.files.maxPartitionBytes to the dfs_block_size.
    # https://phabricator.wikimedia.org/T300299
    $sql_files_max_partition_bytes = $::profile::hadoop::common::dfs_block_size

    file { ['/etc/spark3', '/etc/spark3/conf']:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/spark3/conf/spark-defaults.conf':
        content => template('profile/hadoop/spark3/spark3-defaults.conf.erb'),
    }

    file { '/etc/spark3/conf/spark-env.sh':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('profile/hadoop/spark3/spark3-env.sh.erb')
    }

    file { '/etc/spark3/conf/log4j.properties':
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/profile/hadoop/spark3/spark_log4j.properties',
    }

    # If we want to override any Spark 1 yarn shuffle service to run Spark 2 instead.
    # if $install_yarn_shuffle_jar {
    #     # Add Spark 3 spark-yarn-shuffle.jar to the Hadoop Yarn NodeManager classpath.
    #     file { '/usr/local/bin/spark3_yarn_shuffle_jar_install':
    #         source => 'puppet:///modules/profile/hadoop/spark3/spark3_yarn_shuffle_jar_install.sh',
    #         mode   => '0744',
    #     }
    #     exec { 'spark3_yarn_shuffle_jar_install':
    #         command => '/usr/local/bin/spark3_yarn_shuffle_jar_install',
    #         user    => 'root',
    #         # spark3_yarn_shuffle_jar_install will exit 0 if the current installed
    #         # version of spark3 has a yarn shuffle jar installed already.
    #         unless  => '/usr/local/bin/spark3_yarn_shuffle_jar_install',
    #         require => [
    #             File['/usr/local/bin/spark3_yarn_shuffle_jar_install'],
    #             Package['hadoop-client'],
    #         ],
    #     }
    # }

    # if $install_assembly {
    #     file { '/usr/local/bin/spark3_upload_assembly.sh':
    #         source => 'puppet:///modules/profile/hadoop/spark3/spark3_upload_assembly.sh',
    #         owner  => 'hdfs',
    #         group  => 'root',
    #         mode   => '0550',
    #     }
    #
    #     kerberos::exec { 'spark3_upload_assembly':
    #         command => '/usr/local/bin/spark3_upload_assembly.sh',
    #         user    => 'hdfs',
    #         # spark3_upload_assembly.sh will exit 0 if the current installed
    #         # version of spark3 has a spark3-assembly.zip file already uplaoded to HDFS.
    #         unless  => '/usr/local/bin/spark3_upload_assembly.sh',
    #         require => Package['spark3'],
    #     }
    # }

    if $driver_port {
        $driver_port_max = $driver_port + $port_max_retries
        ferm::service { 'spark3-driver':
            proto  => 'tcp',
            port   => "${driver_port}:${driver_port_max}",
            srange => '$ANALYTICS_NETWORKS',
        }
    }

    if $driver_blockmanager_port {
        $driver_blockmanager_port_max = $driver_blockmanager_port + $port_max_retries
        ferm::service { 'spark3-driver-blockmanager':
            proto  => 'tcp',
            port   => "${driver_blockmanager_port}:${driver_blockmanager_port_max}",
            srange => '$ANALYTICS_NETWORKS',
        }
    }

    if $ui_port {
        $ui_port_max = $ui_port + $port_max_retries
        ferm::service { 'spark3-ui-port':
            proto  => 'tcp',
            port   => "${ui_port}:${ui_port_max}",
            srange => '$ANALYTICS_NETWORKS',
        }
    }

    # TODO: This directory is currently managed by the spark2 profile.
    #       Uncomment when spark3 takes over.
    # if $local_dir {
    #     file { $local_dir:
    #         ensure => directory,
    #         mode   => '1777',
    #         owner  => 'root',
    #         group  => 'root',
    #     }
    # }
}
