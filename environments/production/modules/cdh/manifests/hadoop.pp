# == Class cdh::hadoop
#
# Installs the main Hadoop/HDFS packages and config files.  This
# By default this will set Hadoop config files to run YARN (MapReduce 2).
#
# This assumes that your JBOD mount points are already
# formatted and mounted at the locations listed in $datanode_mounts.
#
# dfs.datanode.data.dir will be set to each of ${dfs_data_dir_mounts}/$data_path
# yarn.nodemanager.local-dirs will be set to each of ${dfs_data_dir_mounts}/$yarn_local_path
# yarn.nodemanager.log-dirs will be set to each of ${dfs_data_dir_mounts}/$yarn_logs_path
#
# == Parameters
#
#   [*namenode_hosts*]
#     Array of NameNode host(s).  The first entry in this
#     array will be the primary NameNode. The primary NameNode
#     will also be used as the host for the historyserver, proxyserver,
#     and resourcemanager.Use multiple hosts hosts if you configuring Hadoop
#     with HA NameNodes.
#
#   [*dfs_name_dir*]
#     Path to hadoop NameNode name directory. This can be an array of paths
#     or a single string path.
#
#   [*cluster_name*]
#     Arbitrary logical HDFS cluster name.  This will be used
#     as the nameserivce id if you set $ha_enabled to true.
#     Default: 'cdh'
#
#   [*journalnode_hosts*]
#     Array of JournalNode hosts. If this is provided, Hadoop will be configured
#     to expect to have a primary NameNode as well as at least
#     one Standby NameNode for use in high availibility mode.
#
#   [*dfs_journalnode_edits_dir*]
#     Path to JournalNode edits dir. This will be ignored if $ha_enabled is false.
#
#   [*datanode_mounts*]
#     Array of JBOD mount points. Hadoop datanode and mapreduce/yarn
#     directories will be here.
#
#   [*dfs_data_path*]
#     Path relative to JBOD mount point for HDFS data directories.
#
#   [*dfs_namenode_handler_count*]
#     The number of server threads for the namenode. The Hadoop RPC server consists
#     of a single RPC queue per port and multiple handler (worker) threads that dequeue
#     and process requests. If the number of handlers is insufficient, then the RPC queue
#     starts building up and eventually overflows.
#     Default: undef
#
#   [*resourcemanager_hosts*]
#     Array of hosts on which ResourceManager is running.  If this has
#     more than one host in it AND $zookeeper_hosts is set, HA YARN ResourceManager
#     and automatic failover will be enabled. This defaults to the value provided
#     for $namenode_hosts. Please be sure to include cdh::hadoop::resourcemanager
#     directly on any standby RM hosts (The master RM will be included automatically
#     when you include cdh::hadoop::master).
#
#   [*fs_trash_checkpoint_interval*]
#     Number of minutes between trash checkpoints. Should be smaller or equal
#     to fs.trash.interval. If zero, the value is set to the value of fs.trash.interval.
#     Every time the checkpointer runs it creates a new checkpoint out of current
#     and removes checkpoints created more than fs.trash.interval minutes ago.
#     Default: undef
#
#   [*fs_trash_interval*]
#     Number of minutes after which a HDFS checkpoint gets deleted.
#     If zero, the trash feature is disabled. This option may be configured both
#     on the server and the client. If trash is disabled server side then the
#     client side configuration is checked. If trash is enabled on the server side
#     then the value configured on the server is used and the client configuration
#     value is ignored.
#     Default: undef
#
#   [*zookeeper_hosts*]
#     Array of Zookeeper hosts to use for HA failover. If provided, HA YARN Resourcemanager
#     will be enabled. Also if set AND $ha_enabled for HDFS is also set,
#     automatic failover for HDFS NameNodes will be enabled.
#     Default: undef
#
#   [*enable_jmxremote*]
#     Enables remote JMX connections for all Hadoop services.
#     Ports are not currently configurable.
#     Default: true.
#
#   [*yarn_local_path*]
#     Path relative to JBOD mount point for yarn local directories.
#
#   [*yarn_logs_path*]
#     Path relative to JBOD mount point for yarn log directories.
#
#   [*dfs_block_size*]
#     HDFS block size in bytes.  Default 64MB.
#
#   [*io_file_buffer_size*]
#     The size of buffer for use in sequence files. The size of this buffer
#     should probably be a multiple of hardware page size (4096 on Intel x86),
#     and it determines how much data is buffered during read and write operations.
#     Default: undef
#
#   [*map_tasks_maximum*]
#     The maximum number of map tasks that will be run simultaneously by a task tracker.
#     Default: undef
#
#   [*reduce_tasks_maximum*]
#     The maximum number of reduce tasks that will be run simultaneously by a task tracker.
#     Default: undef
#
#   [*mapreduce_job_reuse_jvm_num_tasks*]
#
#   [*map_memory_mb*]
#     The amount of memory to request from the scheduler for each map task.
#     Default: undef
#
#   [*reduce_memory_mb*]
#     The amount of memory to request from the scheduler for each reduce task.
#     Default: undef
#
#   [*mapreduce_task_io_sort_mb*]
#     The total amount of buffer memory to use while sorting files, in megabytes
#     By default, gives each merge stream 1MB, which should minimize seeks.
#     Default: undef
#
#   [*mapreduce_task_io_sort_factor*]
#     The number of streams to merge at once while sorting files.
#     This determines the number of open file handles.
#     Default: undef
#
#   [*mapreduce_map_java_opts*]
#     Java opts to pass to map tasks.
#     Default: undef
#
#   [*mapreduce_history_java_opts*]
#     Java opts for the MapReduce History server process.
#
#   [*mapreduce_child_java_opts*]
#
#   [*yarn_app_mapreduce_am_resource_mb*]
#     The amount of memory the MR AppMaster needs.
#
#   [*yarn_app_mapreduce_am_command_opts*]
#     Java opts for the MR App Master processes. The following symbol, if
#     present, will be interpolated: @taskid@ is replaced by current TaskID.
#
#   [*yarn_app_mapreduce_am_job_client_port_range*]
#     Range of ports that the MapReduce AM can use when binding.
#     Leave blank if you want all possible ports. For example. 50000-50050,50100-50200.
#     Default: undef
#
#   [*mapreduce_shuffle_port*]
#     Default port that the ShuffleHandler will run on.
#     ShuffleHandler is a service run at the NodeManager to facilitate transfers
#     of intermediate Map outputs to requesting Reducers.
#     Default: undef
#
#   [*mapreduce_intermediate_compression*]
#     If true, intermediate MapReduce data will be compressed.
#     Default: true.
#
#   [*mapreduce_intermediate_compression_codec*]
#     Codec class to use for intermediate compression.
#     Default: org.apache.hadoop.io.compress.DefaultCodec
#
#   [*mapreduce_output_compession*]
#     If true, final output of MapReduce jobs will be compressed.
#     Default: false.
#
#   [*mapreduce_output_compession_codec*]
#     Codec class to use for final output compression.
#     Default: org.apache.hadoop.io.compress.DefaultCodec
#
#   [*mapreduce_output_compession_type*]
#     Whether to output compress on BLOCK or RECORD level.
#     Default: RECORD
#
#   [*yarn_nodemanager_resource_memory_mb*]
#
#   [*yarn_nodemanager_resource_cpu_vcores*]
#     Default: max($::processorcount - 1, 1)
#
#   [*yarn_nodemanager_nofiles_ulimit*]
#     Default: 65536
#
#   [*yarn_scheduler_minimum_allocation_mb*]
#     The minimum allocation for every container request at the RM,
#     in MBs. Memory requests lower than this won't take effect, and
#     the specified value will get allocated at minimum.
#
#   [*yarn_scheduler_maximum_allocation_mb*]
#     The maximum allocation for every container request at the RM,
#     in MBs. Memory requests higher than this won't take effect, and
#     will get capped to this value.
#
#   [*yarn_scheduler_minimum_allocation_vcores*]
#     The minimum allocation for every container request at the RM,
#     in terms of virtual CPU cores. Requests lower than this won't
#     take effect, and the specified value will get allocated the minimum.
#     Default: undef (1)
#
#   [*yarn_scheduler_maximum_allocation_vcores*]
#     The maximum allocation for every container request at the RM,
#     in terms of virtual CPU cores. Requests higher than this won't
#     take effect, and will get capped to this value.
#     Default: undef (32)
#
#   [*yarn_resourcemanager_scheduler_class*]
#     If you change this (e.g. to FairScheduler), you should also provide
#     your own scheduler config .xml files outside of the cdh module.
#
#   [*yarn_log_aggregation_retain_seconds*]
#     How long (in secs) to keep aggregation logs before deleting them.
#     -1 disables it. Be careful, if you set this too small
#     you will spam the name node.
#     If yarn.log-aggregation.retain-check-interval-seconds is not set
#     or set to 0 or a negative value (default) then the check interval is
#     one-tenth of the aggregated log retention time.
#
#   [*yarn_log_aggregation_retain_check_interval_seconds*]
#     How long to wait between aggregated log retention checks.
#
#   [*hadoop_heapsize*]
#     Xmx for NameNode and DataNode.
#     Default: undef
#
#   [*hadoop_namenode_opts*]
#     Any additional opts to pass to NameNode node on startup.
#     Default: undef
#
#   [*yarn_heapsize*]
#     Xmx for YARN Daemons.
#     Default: undef
#
#   [*dfs_datanode_hdfs_blocks_metadata_enabled*]
#     Boolean which enables backend datanode-side support for the experimental
#     DistributedFileSystem#getFileVBlockStorageLocations API..
#     This is required if you want to use Impala.
#     Default: undef (false)
#
#   [*ganglia_hosts*]
#     Set this to an array of ganglia host:ports if you want to enable ganglia
#     sinks in hadoop-metrics2.properites.
#
#   [*net_topology_script_content*]
#     Rendered content of script that will be invoked to resolve node
#     names to row or rack assignments.
#     Default: undef
#
#   [*fair_scheduler_template*]
#     The fair-scheduler.xml queue configuration template.
#     If you set this to false or undef, FairScheduler will
#     be disabled.
#     Default: cdh/hadoop/fair-scheduler.xml.erb
#
#   [*core_site_extra_properties*]
#     Hash of extra property names to values that will be
#     be rendered in core-site.xml.erb.
#     Default: undef
#
#   [*yarn_site_extra_properties*]
#     Hash of extra property names to values that will be
#     be rendered in yarn-site.xml.erb.
#     Default: undef
#
#   [*hdfs_site_extra_properties*]
#     Hash of extra property names to values that will be
#     be rendered in hdfs-site.xml.erb.
#     Default: undef
#
#   [*mapred_site_extra_properties*]
#     Hash of extra property names to values that will be
#     be rendered in mapred-site.xml.erb.
#     Default: undef
#
#   [*dfs_datanode_failed_volumes_tolerated*]
#     Maximum amount of disk/volume failures tolerated by the Datanode
#     before shutting down.
#     Default: undef
#
#   [*yarn_nodemanager_container_executor_config*]
#     Hash that contains key/values that will populate the
#     container-executor.cfg file.
#     Default: {}
#
#   [*yarn_resourcemanager_zk_timeout_ms*]
#     Timeout to contact Zookeeper.
#     Default: undef
#
#   [*yarn_resourcemanager_zk_state_store_parent_path*]
#     Zookeeper znode related to the Yarn Resource Manager
#     application ids storage location. Cannot be used
#     with yarn_resourcemanager_fs_state_store_uri.
#     Default: undef
#
#   [*yarn_resourcemanager_fs_state_store_uri*]
#     Path in HDFS of the Yarn Resource Manager
#     application ids storage location. Cannot be used
#     with yarn_resourcemanager_zk_state_store_parent_path.
#     Default: undef
#
#   [*yarn_resourcemanager_fs_state_store_retry_policy*]
#     Tuple 'ms,tries' related to how many tries the HDFS
#     DFS client will do (interleaved with ms of wait time)
#     before trying to contact the HDFS namenode after a failure.
#     Please note: the Hadoop's default is '2000,500', namely
#     500 tries interleaved by 2s each. This affects how much
#     time it will take to the Yarn Resource Manager to pick
#     up the new active HDFS Namenode (in case for example that
#     a HDFS master failover happens while the Resource Manager
#     is bootstrapping, namely trying to load its app ids store).
#     Default: undef
#
#   [*yarn_resourcemanager_max_completed_applications*]
#     Hash that contains key/values that will populate the
#     container-executor.cfg file.
#     Default: 10000
#
class cdh::hadoop(
    $namenode_hosts,
    $dfs_name_dir,
    $cluster_name                                = 'cdh',
    $journalnode_hosts                           = undef,
    $dfs_journalnode_edits_dir                   = undef,

    $datanode_mounts                             = undef,
    $dfs_data_path                               = 'hdfs/dn',
    $dfs_datanode_failed_volumes_tolerated       = undef,
    $dfs_namenode_handler_count                  = undef,

    $resourcemanager_hosts                       = $namenode_hosts,
    $zookeeper_hosts                             = undef,
    $yarn_resourcemanager_zk_timeout_ms          = undef,
    $yarn_resourcemanager_zk_state_store_parent_path = undef,
    $yarn_resourcemanager_fs_state_store_uri     = undef,
    $yarn_resourcemanager_fs_state_store_retry_policy = '2000,10',
    $yarn_resourcemanager_max_completed_applications = 10000,

    $java_home                                   = undef,

    $fs_trash_interval                           = undef,
    $fs_trash_checkpoint_interval                = undef,

    $yarn_local_path                             = 'yarn/local',
    $yarn_logs_path                              = 'yarn/logs',
    $dfs_block_size                              = 67108864, # 64MB default
    $enable_jmxremote                            = true,
    $webhdfs_enabled                             = false,
    $httpfs_enabled                              = false,
    $io_file_buffer_size                         = undef,
    $mapreduce_system_dir                        = undef,
    $mapreduce_map_tasks_maximum                 = undef,
    $mapreduce_reduce_tasks_maximum              = undef,
    $mapreduce_job_reuse_jvm_num_tasks           = undef,
    $mapreduce_reduce_shuffle_parallelcopies     = undef,
    $mapreduce_map_memory_mb                     = undef,
    $mapreduce_reduce_memory_mb                  = undef,
    $yarn_app_mapreduce_am_resource_mb           = undef,
    $yarn_app_mapreduce_am_command_opts          = undef,
    $yarn_app_mapreduce_am_job_client_port_range = undef,
    $mapreduce_task_io_sort_mb                   = undef,
    $mapreduce_task_io_sort_factor               = undef,
    $mapreduce_map_java_opts                     = undef,
    $mapreduce_reduce_java_opts                  = undef,
    $mapreduce_history_java_opts                 = undef,
    $mapreduce_shuffle_port                      = undef,
    $mapreduce_intermediate_compression          = false,
    $mapreduce_intermediate_compression_codec    = 'org.apache.hadoop.io.compress.DefaultCodec',
    $mapreduce_output_compression                = false,
    $mapreduce_output_compression_codec          = 'org.apache.hadoop.io.compress.DefaultCodec',
    $mapreduce_output_compression_type           = 'RECORD',
    $yarn_nodemanager_resource_memory_mb         = undef,
    $yarn_nodemanager_resource_cpu_vcores        = max($::processorcount - 1, 1 + 0),
    $yarn_nodemanager_nofiles_ulimit             = 65536,
    $yarn_log_aggregation_retain_seconds         = 7776000,
    $yarn_log_aggregation_retain_check_interval_seconds = 86400,
    $yarn_scheduler_minimum_allocation_mb        = undef,
    $yarn_scheduler_maximum_allocation_mb        = undef,
    $yarn_scheduler_minimum_allocation_vcores    = undef,
    $yarn_scheduler_maximum_allocation_vcores    = undef,
    $hadoop_heapsize                             = undef,
    $hadoop_namenode_opts                        = undef,
    $hadoop_datanode_opts                        = undef,
    $hadoop_journalnode_opts                     = undef,
    $yarn_resourcemanager_opts                   = undef,
    $yarn_nodemanager_opts                       = undef,
    $yarn_heapsize                               = undef,
    $dfs_datanode_hdfs_blocks_metadata_enabled   = undef,
    $ganglia_hosts                               = undef,
    $net_topology_script_content                 = undef,
    $fair_scheduler_template                     = 'cdh/hadoop/fair-scheduler.xml.erb',
    $core_site_extra_properties                  = undef,
    $yarn_site_extra_properties                  = undef,
    $hdfs_site_extra_properties                  = undef,
    $mapred_site_extra_properties                = undef,
    $yarn_nodemanager_container_executor_config  = undef,
    $namenode_jmxremote_port                     = 9980,
    $datanode_jmxremote_port                     = 9981,
    $journalnode_jmxremote_port                  = 9982,
    $resourcemanager_jmxremote_port              = 9983,
    $nodemanager_jmxremote_port                  = 9984,
    $proxyserver_jmxremote_port                  = 9985,
    $mapreduce_history_jmxremote_port            = 9986,
) {

    if $yarn_resourcemanager_fs_state_store_uri and $yarn_resourcemanager_zk_state_store_parent_path {
        fail('yarn_resourcemanager_fs_state_store_uri and
              yarn_resourcemanager_zk_state_store_parent_path are mutually exclusive')
    }

    # If $dfs_name_dir is a list, this will be the
    # first entry in the list.  Else just $dfs_name_dir.
    # This used in a couple of execs throughout this module.
    $dfs_name_dir_main = inline_template('<%= (@dfs_name_dir.class == Array) ? @dfs_name_dir[0] : @dfs_name_dir %>')

    # Config files are installed into a directory
    # based on the value of $cluster_name.
    $config_directory = "/etc/hadoop/conf.${cluster_name}"

    # Set a boolean used to indicate that HA NameNodes
    # are intended to be used for this cluster.  HA NameNodes
    # require the JournalNodes are configured.
    $ha_enabled = $journalnode_hosts ? {
        undef   => false,
        default => true,
    }
    # If $ha_enabled is true, use $cluster_name as $nameservice_id.
    $nameservice_id = $ha_enabled ? {
        true    => $cluster_name,
        default => undef,
    }
    # Assume the primary namenode is the first entry in $namenode_hosts,
    # Set a variable here for reference in other classes.
    $primary_namenode_host = $namenode_hosts[0]
    # This is the primary NameNode ID used to identify
    # a NameNode when running HDFS with a logical nameservice_id.
    # We can't use '.' characters because NameNode IDs
    # will be used in the names of some Java properties,
    # which are '.' delimited.
    $primary_namenode_id   = inline_template('<%= @primary_namenode_host.tr(\'.\', \'-\') %>')


    # Set a boolean used to indicate that HA YARN
    # is intended to be used for this cluster.  HA YARN
    # require the zookeeper is configured, and that
    # multiple ResourceManagers are specificed.
    if $ha_enabled and size($resourcemanager_hosts) > 1 and $zookeeper_hosts {
        $yarn_ha_enabled = true
        $yarn_cluster_id = $cluster_name
    }
    else {
        $yarn_ha_enabled = false
        $yarn_cluster_id = undef
    }

    # Assume the primary resourcemanager is the first entry in $resourcemanager_hosts
    # Set a variable here for reference in other classes.
    $primary_resourcemanager_host = $resourcemanager_hosts[0]


    package { ['hadoop-client', 'libhdfs0']:
        ensure => 'installed'
    }

    # Explicitly adding the 'hdfs'/'yarn'/'mapred' users
    # to the catalog, even if created by the hadoop-common package,
    # to allow other resources to require them if needed.
    user { 'yarn':
        gid        => 'yarn',
        comment    => 'Hadoop YARN',
        home       => '/var/lib/hadoop-yarn',
        shell      => '/bin/bash',
        managehome => false,
        system     => true,
        require    => Package['hadoop-client'],
    }

    user { 'hdfs':
        gid        => 'hdfs',
        comment    => 'Hadoop HDFS',
        home       => '/var/lib/hadoop-hdfs',
        shell      => '/bin/bash',
        managehome => false,
        system     => true,
        require    => Package['hadoop-client'],
    }

    user { 'mapred':
        gid        => 'mapred',
        comment    => 'Hadoop MapReduce',
        home       => '/var/lib/hadoop-mapreduce',
        shell      => '/bin/bash',
        managehome => false,
        system     => true,
        require    => Package['hadoop-client'],
    }

    # Create the $cluster_name based $config_directory.
    file { $config_directory:
        ensure  => 'directory',
        require => Package['hadoop-client'],
    }
    cdh::alternative { 'hadoop-conf':
        link => '/etc/hadoop/conf',
        path => $config_directory,
    }

    # Use $net_topology_script_content as net-topology.sh if it was given.
    $net_topology_script_ensure = $net_topology_script_content ? {
        undef   => 'absent',
        default => 'present',
    }
    $net_topology_script_path = $net_topology_script_content ? {
        undef   => undef,
        default => "${config_directory}/net-topology.sh",
    }
    if $net_topology_script_path{
        file { $net_topology_script_path:
            ensure  => $net_topology_script_ensure,
            mode    => '0755',
            content => $net_topology_script_content,
        }
    }

    $fair_scheduler_enabled = $fair_scheduler_template ? {
        undef   => false,
        false   => false,
        default => true,
    }

    $fair_scheduler_allocation_file_ensure = $fair_scheduler_enabled ? {
        true  => 'present',
        false => 'absent',
    }
    # FairScheduler can be enabled
    # and this file will be used to configure
    # FairScheduler queues.
    file { "${config_directory}/fair-scheduler.xml":
        ensure  => $fair_scheduler_allocation_file_ensure,
        content => template($fair_scheduler_template),
    }

    file { "${config_directory}/log4j.properties":
        content => template('cdh/hadoop/log4j.properties.erb'),
    }

    file { "${config_directory}/core-site.xml":
        content => template('cdh/hadoop/core-site.xml.erb'),
    }

    file { "${config_directory}/hdfs-site.xml":
        content => template('cdh/hadoop/hdfs-site.xml.erb'),
    }

    file { "${config_directory}/hadoop-env.sh":
        content => template('cdh/hadoop/hadoop-env.sh.erb'),
    }

    file { "${config_directory}/mapred-site.xml":
        content => template('cdh/hadoop/mapred-site.xml.erb'),
    }

    file { "${config_directory}/yarn-site.xml":
        content => template('cdh/hadoop/yarn-site.xml.erb'),
    }

    file { "${config_directory}/yarn-env.sh":
        content => template('cdh/hadoop/yarn-env.sh.erb'),
    }

    if $yarn_nodemanager_container_executor_config {
        file { "${config_directory}/container-executor.cfg":
            owner   => 'root',
            group   => 'hadoop',
            mode    => '0550',
            content => template('cdh/hadoop/container-executor.cfg.erb'),
        }
    }

    # Render hadoop-metrics2.properties
    # if we have Ganglia Hosts to send metrics to.
    $hadoop_metrics2_ensure = $ganglia_hosts ? {
        undef   => 'absent',
        default => 'present',
    }
    file { "${config_directory}/hadoop-metrics2.properties":
        ensure  => $hadoop_metrics2_ensure,
        content => template('cdh/hadoop/hadoop-metrics2.properties.erb'),
    }
}
