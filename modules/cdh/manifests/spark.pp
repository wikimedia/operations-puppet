# == Class cdh::spark
# Installs spark set up to work in YARN mode.
# You should include this on your client nodes.
# This does not need to be on all worker nodes.
#
# == Parameters
# $master_host                                      - If set, Spark will be configured to work in standalone mode,
#                                                     rather than in YARN.  Include cdh::spark::master on this host
#                                                     and cdh::spark::worker on all standalone Spark Worker nodes.
#                                                     Default: undef
#
# $worker_cores                                     - Number of cores to allocate per spark worker.
#                                                     This is only used in standalone mode.  Default: undef ($::processorcount)
#
# $worker_memory                                    - Total amount of memory workers are allowed to use on a node.
#                                                     This is only used in standalone mode.  Default:  undef ($::memorysize_mb - 1024)
#
# $worker_instances                                 - Number of worker instances to run on a node.  Note that $worker_cores
#                                                     will apply to each worker.  If you increase this, make sure to
#                                                     make $worker_cores smaller appropriately.
#                                                     This is only used in standalone mode.  Default: undef (1)
#
# $daemon_memory                                    - Memory to allocate to the Spark master and worker daemons themselves.
#                                                     This is only used in standalone mode.  Default: undef (512m)
#
# $dynamic_allocation_enabled                       - If set, Spark will be configured to use Dynamic Resource Allocation.
#                                                     This is only available in YARN mode. Default: true
#
# $dynamic_allocation_executor_idle_timeout         - Corresponds to the related Spark Dynamic Resource Allocation timeout setting.
#                                                     This is only available in YARN mode. Default: '60s'
#
# $dynamic_allocation_cached_executor_idle_timeout  - Corresponds to the related Spark Dynamic Resource Allocation timeout setting
#                                                     This is only available in YARN mode. Default: '3600s'
#
# $use_kerberos                                     - Use Kerberos authentication to create HDFS directories.
#
class cdh::spark(
    $master_host                                     = undef,
    $worker_cores                                    = undef,
    $worker_memory                                   = undef,
    $worker_instances                                = undef,
    $daemon_memory                                   = undef,
    $dynamic_allocation_enabled                      = true,
    $dynamic_allocation_executor_idle_timeout        = '60s',
    $dynamic_allocation_cached_executor_idle_timeout = '3600s',
    $use_kerberos                                    = false,
)
{
    # Spark requires Hadoop configs installed.
    Class['cdh::hadoop'] -> Class['cdh::spark']

    # If $standalone_master_host was set,
    # then we will be configuring a standalone spark cluster.
    $standalone_enabled = $master_host ? {
        undef   => false,
        default => true,
    }

    if $standalone_enabled and $dynamic_allocation_enabled {
        fail('Spark Dynamic Resource Allocation is only available in YARN mode.')
    }

    package { ['spark-core', 'spark-python']:
        ensure => 'installed',
    }

    $config_directory = "/etc/spark/conf.${cdh::hadoop::cluster_name}"
    # Create the $cluster_name based $config_directory.
    file { $config_directory:
        ensure  => 'directory',
        require => Package['spark-core'],
    }
    cdh::alternative { 'spark-conf':
        link => '/etc/spark/conf',
        path => $config_directory,
    }

    # Only need to ensure these directories once.
    # TODO: In default YARN mode, how to make sure we only check these directories from one puppet host?
    if !$standalone_enabled or $master_host == $::fqdn {
        # sudo -u hdfs hdfs dfs -mkdir /user/spark
        # sudo -u hdfs hdfs dfs -chmod 0775 /user/spark
        # sudo -u hdfs hdfs dfs -chown spark:spark /user/spark
        cdh::hadoop::directory { '/user/spark':
            owner        => 'spark',
            group        => 'spark',
            mode         => '0755',
            use_kerberos => $use_kerberos,
            require      => Package['spark-core'],
        }

        cdh::hadoop::directory { '/user/spark/share':
            owner        => 'spark',
            group        => 'spark',
            mode         => '0755',
            use_kerberos => $use_kerberos,
            require      => Cdh::Hadoop::Directory['/user/spark'],

        }
        cdh::hadoop::directory { '/user/spark/share/lib':
            owner        => 'spark',
            group        => 'spark',
            mode         => '0755',
            use_kerberos => $use_kerberos,
            require      => Cdh::Hadoop::Directory['/user/spark/share'],
        }

        cdh::hadoop::directory { ['/user/spark/applicationHistory']:
            owner        => 'spark',
            group        => 'spark',
            mode         => '1777',
            use_kerberos => $use_kerberos,
            require      => Cdh::Hadoop::Directory['/user/spark'],
        }
    }

    $namenode_address = $::cdh::hadoop::ha_enabled ? {
        true    => $cdh::hadoop::nameservice_id,
        default => $cdh::hadoop::primary_namenode_host,
    }

    if !$standalone_enabled {
        # Put Spark assembly jar into HDFS so that it d
        # doesn't have to be loaded for each spark job submission.

        $spark_jar_hdfs_path = "hdfs://${namenode_address}/user/spark/share/lib/spark-assembly.jar"
        kerberos::exec { 'spark_assembly_jar_install':
            command      => "/usr/bin/hdfs dfs -put -f /usr/lib/spark/lib/spark-assembly.jar ${spark_jar_hdfs_path}",
            unless       => '/usr/bin/hdfs dfs -ls /user/spark/share/lib/spark-assembly.jar | grep -q /user/spark/share/lib/spark-assembly.jar',
            user         => 'spark',
            require      => Cdh::Hadoop::Directory['/user/spark/share/lib'],
            before       => [
                File["${config_directory}/spark-env.sh"],
                File["${config_directory}/spark-defaults.conf"]
            ],
            timeout      => 60,
            use_kerberos => $use_kerberos,
        }
    }

    file { "${config_directory}/spark-env.sh":
        content => template('cdh/spark/spark-env.sh.erb'),
    }

    file { "${config_directory}/spark-defaults.conf":
        content => template('cdh/spark/spark-defaults.conf.erb'),
    }

    file { "${config_directory}/log4j.properties":
        source => 'puppet:///modules/cdh/spark/log4j.properties',
    }

    $hive_site_symlink_ensure = defined(Class['cdh::hive']) ? {
        true    => 'link',
        default => 'absent'
    }

    file { "${config_directory}/hive-site.xml":
        ensure => $hive_site_symlink_ensure,
        target => "${::cdh::hive::config_directory}/hive-site.xml",
    }
}
