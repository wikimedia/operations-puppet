# SPDX-License-Identifier: Apache-2.0
# == Class bigtop::hadoop
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
#     Default: 'bigtop'
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
#     for $namenode_hosts. Please be sure to include bigtop::hadoop::resourcemanager
#     directly on any standby RM hosts (The master RM will be included automatically
#     when you include bigtop::hadoop::master).
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
#   [*mapreduce_history_heap_size*]
#     The number of megabytes to be used for the Java heap of the MapReduce History server.
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
#   [*yarn_nodemanager_log_aggregation_compression_type*]
#     This is the compression protocol used to store ran aggregated logs.
#     Possible values: none, gz, lzo
#     Default: none
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
#     your own scheduler config .xml files outside of the bigtop module.
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
#   [*yarn_use_spark_shuffle*]
#     Boolean: If enabled, this will cause yarn to load the spark shuffler
#     service in addition to the mapreduce shuffler service. Options will be
#     added to the yarn-site.xml file. If yarn_use_multi_spark_shuffler is
#     true then that takes precedence over this option, which then has no effect/
#
#   [*yarn_use_multi_spark_shuffler*]
#     Boolean: If enabled, this causes yarn to load support for multiple versions
#     of the spark shuffler service, in addition to the mapreduce shuffler service.
#     This option takes precedence over the yarn_use_spark_shuffle option.
#
#   [*yarn_multi_spark_shuffler_versions*]
#     This is a hash of versions of the spark shuffler for yarn to install, along
#     with their respective port numbers. It is only used if yarn_use_multi_spark_shuffler
#     is true. Default: {} Example: { '3.1' => 7001, '3.3' => 7002, '3.3' => 7003 }
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
#   [*net_topology_script_content*]
#     Rendered content of script that will be invoked to resolve node
#     names to row or rack assignments.
#     Default: undef
#
#   [*net_topology*]
#     A mapping of FQDN hostname to 'rack'.  This will be used by to render the
#     configuration for script that will be used for Hadoop node rack awareness.
#
#
#   [*fair_scheduler_template*]
#     The fair-scheduler.xml queue configuration template.
#     If you set this to false or undef, FairScheduler will
#     be disabled.
#     Default: undef
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
class bigtop::hadoop(
    $namenode_hosts,
    $dfs_name_dir,
    $cluster_name                                       = 'bigtop',
    $journalnode_hosts                                  = undef,
    $dfs_journalnode_edits_dir                          = undef,

    $datanode_mounts                                    = undef,
    $dfs_data_path                                      = 'hdfs/dn',
    $dfs_datanode_failed_volumes_tolerated              = undef,
    $dfs_namenode_handler_count                         = undef,
    $dfs_namenode_service_handler_count                 = undef,
    $dfs_namenode_service_port                          = undef,

    $resourcemanager_hosts                              = $namenode_hosts,
    $zookeeper_hosts                                    = undef,
    $yarn_resourcemanager_zk_timeout_ms                 = undef,
    $yarn_resourcemanager_zk_state_store_parent_path    = undef,
    $yarn_resourcemanager_fs_state_store_uri            = undef,
    $yarn_resourcemanager_fs_state_store_retry_policy   = '2000,10',
    $yarn_resourcemanager_max_completed_applications    = 10000,
    $yarn_node_labels_enabled                           = undef,

    $java_home                                          = undef,

    $fs_trash_interval                                  = undef,
    $fs_trash_checkpoint_interval                       = undef,

    $yarn_local_path                                    = 'yarn/local',
    $yarn_logs_path                                     = 'yarn/logs',
    $dfs_block_size                                     = 67108864, # 64MB default
    $enable_jmxremote                                   = true,
    $webhdfs_enabled                                    = false,
    $httpfs_enabled                                     = false,
    $io_file_buffer_size                                = undef,
    $mapreduce_system_dir                               = undef,
    $mapreduce_map_tasks_maximum                        = undef,
    $mapreduce_reduce_tasks_maximum                     = undef,
    $mapreduce_job_reuse_jvm_num_tasks                  = undef,
    $mapreduce_reduce_shuffle_parallelcopies            = undef,
    $mapreduce_map_memory_mb                            = undef,
    $mapreduce_reduce_memory_mb                         = undef,
    $yarn_app_mapreduce_am_resource_mb                  = undef,
    $yarn_app_mapreduce_am_command_opts                 = undef,
    $yarn_app_mapreduce_am_job_client_port_range        = undef,
    $mapreduce_task_io_sort_mb                          = undef,
    $mapreduce_task_io_sort_factor                      = undef,
    $mapreduce_map_java_opts                            = undef,
    $mapreduce_reduce_java_opts                         = undef,
    $mapreduce_history_java_opts                        = undef,
    $mapreduce_history_heap_size                        = undef,
    $mapreduce_shuffle_port                             = undef,
    $mapreduce_intermediate_compression                 = false,
    $mapreduce_intermediate_compression_codec           = 'org.apache.hadoop.io.compress.DefaultCodec',
    $mapreduce_output_compression                       = false,
    $mapreduce_output_compression_codec                 = 'org.apache.hadoop.io.compress.DefaultCodec',
    $mapreduce_output_compression_type                  = 'RECORD',
    $yarn_nodemanager_log_aggregation_compression_type  = 'gz',
    $yarn_nodemanager_resource_memory_mb                = undef,
    $yarn_nodemanager_resource_cpu_vcores               = max($::processorcount - 1, 1 + 0),
    $yarn_nodemanager_nofiles_ulimit                    = 65536,
    $yarn_log_aggregation_retain_seconds                = 5184000, # 60 days
    $yarn_log_aggregation_retain_check_interval_seconds = 86400,
    $yarn_scheduler_minimum_allocation_mb               = undef,
    $yarn_scheduler_maximum_allocation_mb               = undef,
    $yarn_scheduler_minimum_allocation_vcores           = undef,
    $yarn_scheduler_maximum_allocation_vcores           = undef,
    $yarn_use_spark_shuffle                             = false,
    $yarn_use_multi_spark_shufflers                     = false,
    $yarn_multi_spark_shuffler_versions                 = {},
    $hadoop_heapsize                                    = undef,
    $hadoop_namenode_opts                               = undef,
    $hadoop_datanode_opts                               = undef,
    $hadoop_journalnode_opts                            = undef,
    $yarn_resourcemanager_opts                          = undef,
    $yarn_nodemanager_opts                              = undef,
    $yarn_heapsize                                      = undef,
    $dfs_datanode_hdfs_blocks_metadata_enabled          = undef,
    $net_topology_script_content                        = undef,
    $fair_scheduler_template                            = undef,
    $core_site_extra_properties                         = undef,
    $yarn_site_extra_properties                         = undef,
    $hdfs_site_extra_properties                         = undef,
    $mapred_site_extra_properties                       = undef,
    $yarn_nodemanager_container_executor_config         = undef,
    $namenode_jmxremote_port                            = 9980,
    $datanode_jmxremote_port                            = 9981,
    $journalnode_jmxremote_port                         = 9982,
    $resourcemanager_jmxremote_port                     = 9983,
    $nodemanager_jmxremote_port                         = 9984,
    $proxyserver_jmxremote_port                         = 9985,
    $mapreduce_history_jmxremote_port                   = 9986,
    $enable_log4j_extras                                = true,
    Optional[Hash[String, String]] $net_topology        = undef,
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

    # The hadoop package, brought in by hadoop-client and others, contains
    # the /usr/lib/hadoop/libexec/hadoop-config.sh file that is broadly used
    # by daemons to get run-time parameters. One of them is -Djava.net.preferIPv4Stack=true,
    # since in the past (long time ago) Hadoop did not work well with IPv6.
    # This is not the case anymore, as we proved in T225296.
    # In T240255 we discovered that other daemons like Hive are affected by
    # this setting, so instead of trying to override java.net.preferIPv4Stack with
    # multiple statements (first =true then =false for example), let's just
    # remove the problem from the source.
    file_line { 'enable-ipv6-hadoop-comment':
        ensure  => absent,
        line    => '# Disable ipv6 as it can cause issues',
        path    => '/usr/lib/hadoop/libexec/hadoop-config.sh',
        require => Package['hadoop-client'],
    }

    file_line { 'enable-ipv6-hadoop':
        ensure  => absent,
        line    => 'HADOOP_OPTS="$HADOOP_OPTS -Djava.net.preferIPv4Stack=true"',
        path    => '/usr/lib/hadoop/libexec/hadoop-config.sh',
        require => Package['hadoop-client'],
    }

    # We use fixed uid/gids for Hadoop daemons.
    # We manage service system users in puppet classes, but declare
    # commented placeholders for them in the admin module's data.yaml file
    # to ensure that people don't accidentally add uid/gid conflicts.
    $hdfs_uid = 903
    $yarn_uid = 904
    $mapred_uid = 905

    $hadoop_gid = 908

    # Main group gids should match uids.
    $hdfs_gid = $hdfs_uid
    $yarn_gid = $yarn_uid
    $mapred_gid = $mapred_uid

    group { 'hadoop':
        gid => $hadoop_gid,
    }
    group { 'yarn':
        gid => $yarn_gid,
    }
    group { 'mapred':
        gid => $mapred_gid,
    }
    group { 'hdfs':
        gid => $hdfs_gid,
    }

    user { 'yarn':
        gid        => 'yarn',
        uid        => $yarn_uid,
        comment    => 'Hadoop YARN',
        home       => '/var/lib/hadoop-yarn',
        shell      => '/bin/bash',
        managehome => false,
        system     => true,
        groups     => 'hadoop',
        require    => [
            Group['hadoop'], Group['yarn'],
        ],
    }

    user { 'hdfs':
        gid        => 'hdfs',
        uid        => $hdfs_uid,
        comment    => 'Hadoop HDFS',
        home       => '/var/lib/hadoop-hdfs',
        shell      => '/bin/bash',
        managehome => false,
        system     => true,
        groups     => 'hadoop',
        require    => [
            Group['hadoop'], Group['hdfs']
        ],
    }

    user { 'mapred':
        gid        => 'mapred',
        uid        => $mapred_uid,
        comment    => 'Hadoop MapReduce',
        home       => '/var/lib/hadoop-mapreduce',
        shell      => '/bin/bash',
        managehome => false,
        system     => true,
        groups     => 'hadoop',
        require    => [
            Group['hadoop'], Group['mapred'],
        ],
    }


    # The hadoop-client package depends from:
    # ~$ apt-cache depends hadoop-client
    # hadoop-client
    #  Depends: hadoop
    #  Depends: hadoop-hdfs
    #  Depends: hadoop-yarn
    #  Depends: hadoop-mapreduce
    #This means that the users hdfs/yarn/mapred may be created by the
    # debian packages after puppet tries to install hadoop-client, without waiting
    # for the users that we defined in puppet itself (with fixed gid/uids).
    package { ['hadoop-client', 'libhdfs0']:
        ensure  => 'installed',
        require => [
            Group['hadoop'],
            User['yarn', 'hdfs', 'mapred'],
        ]
    }

    # Create the $cluster_name based $config_directory.
    file { $config_directory:
        ensure  => 'directory',
        require => Package['hadoop-client'],
    }
    bigtop::alternative { 'hadoop-conf':
        link => '/etc/hadoop/conf',
        path => $config_directory,
    }

    # Use the wrapper script needed to generate net_topology if provided
    $net_topology_script_ensure = $net_topology_script_content ? {
        undef   => 'absent',
        default => 'present',
    }
    $net_topology_script_path = $net_topology_script_content ? {
        undef   => undef,
        default => '/usr/local/bin/generate_net_topology.sh',
    }

    $net_topology_config_ensure = $net_topology ? {
        undef   => 'absent',
        default => 'present',
    }

    file { '/usr/local/bin/hadoop-hdfs-net-topology.py':
        ensure => $net_topology_config_ensure,
        source => 'puppet:///modules/profile/hadoop/hadoop-hdfs-net-topology.py',
        mode   => '0755',
    }

    file { "${config_directory}/net-topology.ini":
        ensure  => $net_topology_config_ensure,
        content => template('profile/hadoop/net-topology.ini.erb'),
    }

    if $net_topology_script_path{
        file { $net_topology_script_path:
            ensure => $net_topology_script_ensure,
            source => 'puppet:///modules/profile/hadoop/generate_net_topology.sh',
            mode   => '0755',
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

    if $fair_scheduler_enabled {
        # FairScheduler can be enabled
        # and this file will be used to configure
        # FairScheduler queues.
        file { "${config_directory}/fair-scheduler.xml":
            ensure  => $fair_scheduler_allocation_file_ensure,
            content => template($fair_scheduler_template),
        }
    } else {
        file { "${config_directory}/fair-scheduler.xml":
            ensure  => $fair_scheduler_allocation_file_ensure,
        }
    }

    file { "${config_directory}/log4j.properties":
        content => template('bigtop/hadoop/log4j.properties.erb'),
    }

    file { "${config_directory}/core-site.xml":
        content => template('bigtop/hadoop/core-site.xml.erb'),
    }

    file { "${config_directory}/hdfs-site.xml":
        content => template('bigtop/hadoop/hdfs-site.xml.erb'),
    }

    # https://phabricator.wikimedia.org/T276906
    package { 'liblog4j-extras1.2-java': }

    file { "${config_directory}/hadoop-env.sh":
        content => template('bigtop/hadoop/hadoop-env.sh.erb'),
        require => Package['liblog4j-extras1.2-java'],
    }

    file { "${config_directory}/mapred-site.xml":
        content => template('bigtop/hadoop/mapred-site.xml.erb'),
    }

    # We only run the mapreduce history server on the primary namenode
    # and we only need to include this file to configure that service. See #T369278
    if $primary_namenode_host == $facts['networking']['fqdn'] {
        file { "${config_directory}/mapred-env.sh":
            content => template('bigtop/hadoop/mapred-env.sh.erb'),
        }
    }

    # Here we determine whether one or multiple spark shuffle services is available
    # Selecting multiple shufflers overrides the single shuffler configuration. See #T344910
    if $yarn_use_multi_spark_shufflers {
        $yarn_spark_shuffler_list = $yarn_multi_spark_shuffler_versions.keys.map | $version | {
            # Named shufflers are not supported until spark version 3.2
            if $version == '3.1' {
                sprintf('spark_shuffle')
            }
            else {
                sprintf('spark_shuffle_%s', sprintf('%s',$version).regsubst('\.','_'))
            }
        }.join(',')
    } elsif $yarn_use_spark_shuffle {
        $yarn_spark_shuffler_list = 'spark_shuffle'
    }
    # The mapreduce shuffler is always enabled. Append the required list for either single
    # or multiple spark shufflers here.
    if yarn_spark_shuffler_list.length > 0 {
        $yarn_shuffler_list = sprintf('mapreduce_shuffle,%s', $yarn_spark_shuffler_list)
    }
    else {
        $yarn_shuffler_list= 'mapreduce_shuffle'
    }

    file { "${config_directory}/yarn-site.xml":
        content => template('bigtop/hadoop/yarn-site.xml.erb'),
    }

    if $yarn_use_multi_spark_shufflers {
        $yarn_multi_spark_shuffler_versions.each | $version | {
            bigtop::spark::shuffler { $version[0]:
                version          => $version[0],
                port             => $version[1],
                config_directory => $config_directory,
            }
        }
    }
    file { "${config_directory}/yarn-env.sh":
        content => template('bigtop/hadoop/yarn-env.sh.erb'),
    }

    if $yarn_nodemanager_container_executor_config {
        file { "${config_directory}/container-executor.cfg":
            owner   => 'root',
            group   => 'hadoop',
            mode    => '0550',
            content => template('bigtop/hadoop/container-executor.cfg.erb'),
        }
    }
}
