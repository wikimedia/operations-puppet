# == Class profile::hadoop::common
#
# Configures Hadoop common configuration, the baseline for all the other
# services/daemons/clients. This includes the Hadoop client packages as well.
# The main goal of this profile is to keep all the Hadoop cluster daemons/clients
# in sync with one single configuration.
#
# This profile uses some defaults that are good for a generic use case, like
# testing in labs, but probably not for production.
#
# == Parameters
#
#  [*zookeeper_clusters*]
#    List of available/configured Zookeeper clusters and their properties.
#
#  [*zookeeper_cluster_name*]
#    The zookeeper cluster name to use.
#
#  [*resourcemanager_hosts*]
#    List of hostnames acting as Yarn Resource Managers for the cluster.
#
#  [*cluster_name*]
#    Name of the Hadoop cluster.
#    Default:'cdh'
#
#  [*namenode_hosts*]
#    List of hostnames acting as HDFS Namenodes for the cluster.
#
#  [*journalnode_hosts*]
#    List of hostnames acting as HDFS Journalnodes for the cluster.
#
#  [*datanode_mounts*]
#    List of file system partitions to use on each Hadoop worker for HDFS.
#    Default: undef
#
#  [*mapreduce_reduce_shuffle_parallelcopies*]
#    Map-reduce specific setting.
#    Default: undef
#
#  [*mapreduce_task_io_sort_mb*]
#    Map-reduce specific setting.
#    Default: undef
#
#  [*mapreduce_task_io_sort_factor*]
#    Map-reduce specific setting.
#    Default: undef
#
#  [*mapreduce_map_memory_mb*]
#    Map container reserved memory.
#    Default: undef
#
#  [*mapreduce_map_java_opts*]
#    Map container JVM ops settings.
#    Default: undef
#
#  [*mapreduce_reduce_memory_mb*]
#    Reduce container reserved memory.
#    Default: undef
#
#  [*mapreduce_reduce_java_opts*]
#    Reduce container JVM ops settings.
#    Default: undef
#
#  [*yarn_heapsize*]
#    Yarn Node and Resource Manager max heap size.
#    Default: undef
#
#  [*yarn_nodemanager_opts*]
#    Yarn Node Manager JVM opts.
#    Default: undef
#
#  [*yarn_resourcemanager_opts*]
#    Yarn Resource Manager JVM opts.
#    Default: undef
#
#  [*hadoop_heapsize*]
#    HDFS daemons maximum heapsize.
#    Default: undef
#
#  [*hadoop_datanode_opts*]
#    HDFS datanode JVM opts.
#    Default: undef
#
#  [*hadoop_namenode_opts*]
#    JVM opts to pass to the HDFS Namenode daemon.
#    If you change these values please check profile::hadoop::*::namenode_heapsize
#    since some alarms need to be tuned in the master/standby config too.
#    Default: undef
#
#  [*yarn_app_mapreduce_am_resource_mb*]
#    Yarn Application Master container size (Mb).
#    Default: undef
#
#  [*yarn_app_mapreduce_am_command_opts*]
#    Yarn Application Master JVM opts.
#    Default: undef
#
#  [*mapreduce_history_java_opts*]
#    Map-reduce History server JVM opts.
#    Default: undef
#
#  [*yarn_nodemanager_resource_memory_mb*]
#    Map-reduce specific setting.
#    Default: undef
#
#  [*yarn_scheduler_minimum_allocation_mb*]
#    Yarn scheduler specific setting.
#    Default: undef
#
#  [*yarn_scheduler_maximum_allocation_mb*]
#    Yarn scheduler specific setting.
#    Default: undef
#
#  [*yarn_scheduler_minimum_allocation_vcores*]
#    Yarn scheduler specific setting.
#    Default: undef
#
#  [*yarn_scheduler_maximum_allocation_vcores*]
#    Yarn scheduler specific setting.
#    Default: undef
#
class profile::hadoop::common (
    $zookeeper_clusters                       = hiera('zookeeper_clusters'),
    $zookeeper_cluster_name                   = hiera('profile::hadoop::common::zookeeper_cluster_name'),
    $resourcemanager_hosts                    = hiera('profile::hadoop::common::resourcemanager_hosts'),
    $cluster_name                             = hiera('profile::hadoop::common::cluster_name', 'cdh'),
    $namenode_hosts                           = hiera('profile::hadoop::common::namenode_hosts'),
    $journalnode_hosts                        = hiera('profile::hadoop::common::journalnode_hosts'),
    $datanode_mounts                          = hiera('profile::hadoop::common::datanode_mounts', undef),
    $mapreduce_reduce_shuffle_parallelcopies  = hiera('profile::hadoop::common::mapreduce_reduce_shuffle_parallelcopies', undef),
    $mapreduce_task_io_sort_mb                = hiera('profile::hadoop::common::mapreduce_task_io_sort_mb', undef),
    $mapreduce_task_io_sort_factor            = hiera('profile::hadoop::common::mapreduce_task_io_sort_factor', undef),
    $mapreduce_map_memory_mb                  = hiera('profile::hadoop::common::mapreduce_map_memory_mb', undef),
    $mapreduce_map_java_opts                  = hiera('profile::hadoop::common::mapreduce_map_java_opts', undef),
    $mapreduce_reduce_memory_mb               = hiera('profile::hadoop::common::mapreduce_reduce_memory_mb', undef),
    $mapreduce_reduce_java_opts               = hiera('profile::hadoop::common::mapreduce_reduce_java_opts', undef),
    $yarn_heapsize                            = hiera('profile::hadoop::common::yarn_heapsize', undef),
    $yarn_nodemanager_opts                    = hiera('profile::hadoop::common::yarn_nodemanager_opts', undef),
    $yarn_resourcemanager_opts                = hiera('profile::hadoop::common::yarn_resourcemanager_opts', undef),
    $hadoop_heapsize                          = hiera('profile::hadoop::common::hadoop_heapsize', undef),
    $hadoop_datanode_opts                     = hiera('profile::hadoop::common::hadoop_datanode_opts', undef),
    $hadoop_namenode_opts                     = hiera('profile::hadoop::common::hadoop_namenode_opts', undef),
    $yarn_app_mapreduce_am_resource_mb        = hiera('profile::hadoop::common::yarn_app_mapreduce_am_resource_mb', undef),
    $yarn_app_mapreduce_am_command_opts       = hiera('profile::hadoop::common::yarn_app_mapreduce_am_command_opts', undef),
    $mapreduce_history_java_opts              = hiera('profile::hadoop::common::mapreduce_history_java_opts', undef),
    $yarn_nodemanager_resource_memory_mb      = hiera('profile::hadoop::common::yarn_nodemanager_resource_memory_mb', undef),
    $yarn_scheduler_minimum_allocation_mb     = hiera('profile::hadoop::common::yarn_scheduler_minimum_allocation_mb', undef),
    $yarn_scheduler_maximum_allocation_mb     = hiera('profile::hadoop::common::yarn_scheduler_maximum_allocation_mb', undef),
    $yarn_scheduler_minimum_allocation_vcores = hiera('profile::hadoop::common::yarn_scheduler_minimum_allocation_vcores', undef),
    $yarn_scheduler_maximum_allocation_vcores = hiera('profile::hadoop::common::yarn_scheduler_maximum_allocation_vcores', undef),
) {
    # Include Wikimedia's thirdparty/cloudera apt component
    # as an apt source on all Hadoop hosts.  This is needed
    # to install CDH packages from our apt repo mirror.
    require ::profile::cdh::apt

    # Need Java before Hadoop is installed.
    require ::profile::java::analytics

    # Force apt-get update to run before we try to install packages.
    # CDH Packages are in the thirdparty/cloudera apt component,
    # and are made available by profile::cdh::apt.
    Class['::profile::cdh::apt'] -> Exec['apt-get update'] -> Class['::cdh::hadoop']

    $hadoop_var_directory                     = '/var/lib/hadoop'
    $hadoop_name_directory                    = "${hadoop_var_directory}/name"
    $hadoop_data_directory                    = "${hadoop_var_directory}/data"
    $hadoop_journal_directory                 = "${hadoop_var_directory}/journal"

    $zookeeper_hosts = keys($zookeeper_clusters[$zookeeper_cluster_name]['hosts'])

    class { '::cdh::hadoop':
        # Default to using running resourcemanager on the same hosts
        # as the namenodes.
        resourcemanager_hosts                       => $resourcemanager_hosts,
        zookeeper_hosts                             => $zookeeper_hosts,
        dfs_name_dir                                => [$hadoop_name_directory],
        dfs_journalnode_edits_dir                   => $hadoop_journal_directory,

        cluster_name                                => $cluster_name,
        namenode_hosts                              => $namenode_hosts,
        journalnode_hosts                           => $journalnode_hosts,

        datanode_mounts                             => $datanode_mounts,

        yarn_heapsize                               => $yarn_heapsize,
        hadoop_heapsize                             => $hadoop_heapsize,

        yarn_nodemanager_opts                       => $yarn_nodemanager_opts,
        yarn_resourcemanager_opts                   => $yarn_resourcemanager_opts,
        hadoop_namenode_opts                        => $hadoop_namenode_opts,
        hadoop_datanode_opts                        => $hadoop_datanode_opts,
        mapreduce_history_java_opts                 => $mapreduce_history_java_opts,

        yarn_app_mapreduce_am_resource_mb           => $yarn_app_mapreduce_am_resource_mb,
        yarn_app_mapreduce_am_command_opts          => $yarn_app_mapreduce_am_command_opts,
        yarn_nodemanager_resource_memory_mb         => $yarn_nodemanager_resource_memory_mb,
        yarn_scheduler_minimum_allocation_mb        => $yarn_scheduler_minimum_allocation_mb,
        yarn_scheduler_maximum_allocation_mb        => $yarn_scheduler_maximum_allocation_mb,
        yarn_scheduler_minimum_allocation_vcores    => $yarn_scheduler_minimum_allocation_vcores,
        yarn_scheduler_maximum_allocation_vcores    => $yarn_scheduler_maximum_allocation_vcores,

        # 256 MB
        dfs_block_size                              => 268435456,
        io_file_buffer_size                         => 131072,

        # Turn on Snappy compression by default for maps and final outputs
        mapreduce_intermediate_compression_codec    => 'org.apache.hadoop.io.compress.SnappyCodec',
        mapreduce_output_compression                => true,
        mapreduce_output_compression_codec          => 'org.apache.hadoop.io.compress.SnappyCodec',
        mapreduce_output_compression_type           => 'BLOCK',

        mapreduce_job_reuse_jvm_num_tasks           => 1,

        mapreduce_reduce_shuffle_parallelcopies     => $mapreduce_reduce_shuffle_parallelcopies,
        mapreduce_task_io_sort_mb                   => $mapreduce_task_io_sort_mb,
        mapreduce_task_io_sort_factor               => $mapreduce_task_io_sort_factor,
        mapreduce_map_memory_mb                     => $mapreduce_map_memory_mb,
        mapreduce_map_java_opts                     => $mapreduce_map_java_opts,
        mapreduce_reduce_memory_mb                  => $mapreduce_reduce_memory_mb,
        mapreduce_reduce_java_opts                  => $mapreduce_reduce_java_opts,

        net_topology_script_template                => 'profile/hadoop/net-topology.py.erb',

        # This needs to be set in order to use Impala
        dfs_datanode_hdfs_blocks_metadata_enabled   => true,

        # Use fair-scheduler.xml.erb to define FairScheduler queues.
        fair_scheduler_template                     => 'profile/hadoop/fair-scheduler.xml.erb',

        # Yarn App Master possible port ranges
        yarn_app_mapreduce_am_job_client_port_range => '55000-55199',

        core_site_extra_properties                  => {
            # Allow superset running as 'superset' user on thorium.eqiad.wmnet
            # to run jobs as users in the analytics-users and analytics-privatedata-users groups.
            'hadoop.proxyusers.superset.hosts'  => 'thorium.eqiad.wmnet',
            'hadoop.proxyusers.superset.groups' => 'analytics-users,analytics-privatedata-users',
        },

        yarn_site_extra_properties                  => {
            # Enable FairScheduler preemption. This will allow the essential queue
            # to preempt non-essential jobs.
            'yarn.scheduler.fair.preemption'                                                => true,
            # Let YARN wait for at least 1/3 of nodes to present scheduling
            # opportunties before scheduling a job for certain data
            # on a node on which that data is not present.
            'yarn.scheduler.fair.locality.threshold.node'                                   => '0.33',
            # After upgrading to CDH 5.4.0, we are encountering this bug:
            # https://issues.apache.org/jira/browse/MAPREDUCE-5799
            # This should work around the problem.
            'yarn.app.mapreduce.am.env'                                                     => 'LD_LIBRARY_PATH=/usr/lib/hadoop/lib/native',
            # The default of 90.0 for this was marking older dells as unhealthy when they still
            # had 2TB of space left.  99% will mark them at unhealthy with they still have
            # > 200G free.
            'yarn.nodemanager.disk-health-checker.max-disk-utilization-per-disk-percentage' => '99.0',
        },
    }

    class { '::ores::base': }

    if $::realm == 'labs' {
        # Hadoop directories in labs should be created by puppet.
        # This conditional could be added to each worker,master,standby
        # classes, but since it doesn't hurt to have these directories
        # in labs, and since I don't want to add the $::realm conditionals
        # in each class, I do it here.
        file { [
            $hadoop_var_directory,
            $hadoop_data_directory,
        ]:
            ensure => 'directory',
            before => Class['cdh::hadoop'],
        }
    }
}
