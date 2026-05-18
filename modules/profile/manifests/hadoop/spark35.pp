# SPDX-License-Identifier: Apache-2.0
# == Class profile::hadoop::spark35
#
# Installs and configures Spark 3.5 from the conda-analytics-next package.
# Parallel to profile::hadoop::spark3; both versions can coexist on a node.
#
# Users invoke Spark 3.5 via the spark35-* wrapper scripts, which set
# SPARK_CONF_DIR=/etc/spark35/conf and exec the binaries via /usr/lib/spark35,
# a symlink managed here pointing at the conda-analytics-next prefix.

class profile::hadoop::spark35 (
    String                     $spark_version              = lookup('profile::hadoop::spark35::spark_version',              { 'default_value' => '3.5.8' }),
    Bigtop::Spark::Version     $default_shuffler_version   = lookup('profile::hadoop::spark35::default_shuffler_version',   { 'default_value' => '3.5' }),
    Hash[String, Any]          $extra_settings             = lookup('profile::hadoop::spark35::extra_settings',             { 'default_value' => {} }),
    Stdlib::Port               $driver_port                = lookup('profile::hadoop::spark35::driver_port',                { 'default_value' => 12000 }),
    Stdlib::Port               $driver_blockmanager_port   = lookup('profile::hadoop::spark35::driver_blockmanager_port',   { 'default_value' => 13000 }),
    Stdlib::Port               $ui_port                    = lookup('profile::hadoop::spark35::ui_port',                    { 'default_value' => 4040 }),
    Integer                    $port_max_retries           = lookup('profile::hadoop::spark35::port_max_retries',           { 'default_value' => 100 }),
    Stdlib::Unixpath           $executor_env_ld_lib_path   = lookup('profile::hadoop::spark35::executor_env_ld_lib_path',   { 'default_value' => '/usr/lib/hadoop/lib/native' }),
    Boolean                    $encryption_enabled         = lookup('profile::hadoop::spark35::encryption_enabled',         { 'default_value' => true }),
    Optional[Stdlib::Unixpath] $local_dir                  = lookup('profile::hadoop::spark35::local_dir',                  { 'default_value' => undef }),
    Optional[String]           $event_log_dir              = lookup('profile::hadoop::spark35::event_log_dir',              { 'default_value' => undef }),
    Optional[Boolean]          $event_log_compress         = lookup('profile::hadoop::spark35::event_log_compress',         { 'default_value' => undef }),
    Optional[String]           $spark_yarn_history_address = lookup('profile::hadoop::spark35::spark_yarn_history_address', { 'default_value' => undef }),
) {
    require profile::hadoop::common
    require profile::analytics::conda_analytics

    # Used in spark35-env.sh.erb to set the default PYSPARK_PYTHON / PYSPARK_DRIVER_PYTHON
    $python_prefix_global = $conda_analytics::prefix_next

    # Stable path to the spark35 binaries; wrapper scripts exec via this symlink.
    # This means no runtime dpkg-L calls — Puppet writes the path once at deploy time.
    file { '/usr/lib/spark35':
        ensure => link,
        target => $conda_analytics::prefix_next,
    }

    # Wrapper scripts
    $spark35_binaries = ['spark-shell', 'spark-submit', 'pyspark', 'spark-sql', 'spark-class']
    $spark35_binaries.each |String $binary| {
        $cmd = $binary ? {
            'spark-shell' => 'spark35-shell',
            'spark-submit' => 'spark35-submit',
            'pyspark'      => 'spark35-pyspark',
            'spark-sql'    => 'spark35-sql',
            'spark-class'  => 'spark35-class',
        }
        file { "/usr/bin/${cmd}":
            ensure  => file,
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            content => "#!/usr/bin/env bash\n# Managed by Puppet\nexport SPARK_CONF_DIR=/etc/spark35/conf\nexec /usr/lib/spark35/bin/${binary} \"\$@\"\n",
        }
    }

    # Config directories
    file { ['/etc/spark35', '/etc/spark35/conf']:
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    if defined(Class['bigtop::hive']) {
        $hive_enabled = true
        $iceberg_enabled = true
        file { '/etc/spark35/conf/hive-site.xml':
            ensure => 'link',
            target => "${bigtop::hive::config_directory}/hive-site.xml",
        }
    } else {
        $hive_enabled    = false
        $iceberg_enabled = false
    }

    $sql_files_max_partition_bytes = $profile::hadoop::common::dfs_block_size

    $yarn_use_multi_spark_shufflers = $profile::hadoop::common::hadoop_config['yarn_use_multi_spark_shufflers'] ? {
        undef   => false,
        default => $profile::hadoop::common::hadoop_config['yarn_use_multi_spark_shufflers'],
    }

    if $yarn_use_multi_spark_shufflers {
        $default_shuffler_port = $profile::hadoop::common::hadoop_config['yarn_multi_spark_shuffler_versions'][$default_shuffler_version] ? {
            undef   => '7340',
            default => $profile::hadoop::common::hadoop_config['yarn_multi_spark_shuffler_versions'][$default_shuffler_version],
        }
    }

    # Reuse the spark3 templates — they are fully parameterised via @variable
    # and will render correctly with this class's variable bindings.
    file { '/etc/spark35/conf/spark-defaults.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('profile/hadoop/spark3/spark3-defaults.conf.erb'),
    }

    file { '/etc/spark35/conf/spark-env.sh':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('profile/hadoop/spark3/spark3-env.sh.erb'),
    }

    # NOTE: log4j2, not log4j — Spark 3.3+ dropped Log4j 1.x entirely
    file { '/etc/spark35/conf/log4j2.properties':
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/profile/hadoop/spark3/spark35_log4j2.properties',
    }

    # Firewall rules
    if $driver_port {
        firewall::service { 'spark35-driver':
            proto      => 'tcp',
            port_range => [$driver_port, $driver_port + $port_max_retries],
            src_sets   => ['ANALYTICS_NETWORKS'],
        }
    }

    if $driver_blockmanager_port {
        firewall::service { 'spark35-driver-blockmanager':
            proto      => 'tcp',
            port_range => [$driver_blockmanager_port, $driver_blockmanager_port + $port_max_retries],
            src_sets   => ['ANALYTICS_NETWORKS'],
        }
    }

    if $ui_port {
        firewall::service { 'spark35-ui-port':
            proto      => 'tcp',
            port_range => [$ui_port, $ui_port + $port_max_retries],
            src_sets   => ['ANALYTICS_NETWORKS'],
        }
    }

    # The same directory may be defined for both the spark3 and spark35 profiles.
    if $local_dir {
        if !defined(File[$local_dir]) {
            file { $local_dir:
                ensure => directory,
                mode   => '1777',
                owner  => 'root',
                group  => 'root',
            }
        }
    }
}
