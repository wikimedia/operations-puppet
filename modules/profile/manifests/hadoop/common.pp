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
#  [*hadoop_clusters*]
#    List of available/configured Hadoop clusters and their properties.
#
#  [*hadoop_clusters_secrets*]
#    Hash of available/configured Hadoop clusters and their secret properties,
#    like passwords, etc..
#    The following values will be checked in the hash table only if any Yarn/HDFS/MapRed
#    TLS config is enabled (see in the code for the exact values).
#      - 'ssl_keystore_keypassword' -> Related parameter for ssl-(server|client).xml
#      - 'ssl_keystore_password'    -> Related parameter for ssl-(server|client).xml
#      - 'ssl_trustore_password'    -> Related parameter for ssl-(server|client).xml
#    Default: {}
#
#  [*hadoop_cluster_name*]
#    The Hadoop cluster name to pick up config properties from.
#    Default: 'bigtop'
#
#  [*config_override*]
#    Hash of Hadoop properties that override the ones defined in the
#    hadoop_clusters's variable configuration.
#    Default: {}
#
#  [*ensure_ssl_config*]
#    Extra argument to force the profile to not deploy TLS keys if any of the
#    Yarn/HDFS/MapReduce TLS config has been added. This is useful in places where
#    we need the TLS config to be picked (for example to use the encrypted shuffle
#    in map-reduce jobs) but not TLS keys are available for the host.
#    Default: false
#
# == Hadoop properties
#
#  These properties can be added to either hadoop_clusters or config_override's
#  hashes, and they configure specific Hadoop functionality.
#
#  [*zookeeper_cluster_name*]
#    The zookeeper cluster name to use.
#
#  [*resourcemanager_hosts*]
#    List of hostnames acting as Yarn Resource Managers for the cluster.
#
#  [*cluster_name*]
#    Name of the Hadoop cluster.
#
#  [*namenode_hosts*]
#    List of hostnames acting as HDFS Namenodes for the cluster.
#
#  [*journalnode_hosts*]
#    List of hostnames acting as HDFS Journalnodes for the cluster.
#
#  [*datanode_volumes_failed_tolerated*]
#    Number of disk/volume failures tolerated by the datanode before
#    shutting down.
#    Default: undef
#
#  [*hdfs_trash_checkpoint_interval*]
#    Number of minutes to wait before creating a trash checkpoint directory
#    in each home directory.
#    Default: undef
#
#  [*hdfs_trash_interval*]
#    Number of minutes to wait before considering a trash checkpoint stale/old
#    and hence eligible for deletion. This parameter enables the HDFS trash
#    functionality even without setting hdfs_trash_checkpoint_interval, but
#    keep in mind that its default value for hadoop will be 0 (every time the
#    checkpointer runs it creates a new checkpoint out of current and removes
#    checkpoints created more than hdfs_trash_interval minutes ago).
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
#  [*hadoop_journalnode_opts*]
#    HDFS journalnode JVM opts.
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
#  [*yarn_scheduler_minimum_allocation_vcores*]
#    Yarn scheduler specific setting.
#    Default: undef
#
#  [*yarn_scheduler_maximum_allocation_vcores*]
#    Yarn scheduler specific setting.
#    Default: undef
#
#  [*yarn_nodemanager_os_reserved_memory_mb*]
#    Map-reduce specific setting. If set, yarn_nodemanager_resource_memory_mb will
#    be set as total_memory_on_host - yarn_nodemanager_os_reserved_memory_mb.
#    Default: undef
#
#  [*yarn_scheduler_minimum_allocation_mb*]
#    Yarn scheduler specific setting.
#    Default: undef
#
#  [*yarn_scheduler_maximum_allocation_mb*]
#    Yarn scheduler specific setting.  If not set, but reserved_memory_mb and total_memory_mb are,
#    This will be set to total_memory_mb - reserved_memory_mb.
#    Default: undef
#
#  [*java_home*]
#    Sets the JAVA_HOME env. variable in hadoop-env.sh
#
#  [*net_topology*]
#    A mapping of FQDN hostname to 'rack'.  This will be used by net-topology.py.erb
#    to render a script that will be used for Hadoop node rack awareness.
#
#  [*datanode_mounts_prefix*]
#    Gets the list of partitions mounted on the host that match a given prefix
#    to form the list of mountpoints that Yarn and HDFS will rely on.
#    IMPORTANT: make sure that the partitions are mounted on the OS before using this
#    parameter.
#    Default: '/var/lib/hadoop/data'
#
class profile::hadoop::common (
    Hash[String, Any] $zookeeper_clusters      = lookup('zookeeper_clusters'),
    Hash[String, Any] $hadoop_clusters         = lookup('hadoop_clusters'),
    String $cluster_name                       = lookup('profile::hadoop::common::hadoop_cluster_name'),
    Hash[String, Any] $hadoop_clusters_secrets = lookup('hadoop_clusters_secrets', { 'default_value' => {} }),
    Hash[String, Any] $config_override         = lookup('profile::hadoop::common::config_override', { 'default_value' => {} }),
    Boolean $ensure_ssl_config                 = lookup('profile::hadoop::common::ensure_ssl_config', { 'default_value' => false }),
    String $datanode_mounts_prefix             = lookup('profile::hadoop::common::datanode_mounts_prefix', { 'default_value' => '/var/lib/hadoop/data'}),
    Optional[Integer] $min_datanode_mounts     = lookup('profile::hadoop::common::min_datanode_mounts', { 'default_value' => undef }),
) {
    # Properties that are not meant to have undef as default value (a hash key
    # without a correspondent value returns undef) should be listed in here.
    $hadoop_default_config = {
        'hadoop_var_directory' => '/var/lib/hadoop',
        'java_home'            => '/usr/lib/jvm/java-8-openjdk-amd64/jre',
        'dfs_block_size'       => 268435456, # 256M
    }

    # The final Hadoop configuration is obtained merging three hashes:
    # 1) Hadoop properties with a default value different than undef
    # 2) Hadoop properies meant to be shared among all Hadoop daemons/services
    # 3) Hadoop properties that might get overridden by specific Hadoop role/profiles.
    $hadoop_config = $hadoop_default_config + $hadoop_clusters[$cluster_name] + $config_override

    # This is a hash of secrets broken down by cluster name. Useful since 1) these info, like passwords,
    # cannot be retrieved from the above $hadoop_config 2) All the roles that share this profile can
    # get a single source of configuration, that avoids copy/paste config around.
    $hadoop_secrets_config = $hadoop_clusters_secrets[$cluster_name]

    $zookeeper_cluster_name                   = $hadoop_config['zookeeper_cluster_name']
    $yarn_resourcemanager_zk_state_store_parent_path = $hadoop_config['yarn_resourcemanager_zk_state_store_parent_path']
    $yarn_resourcemanager_fs_state_store_uri  = $hadoop_config['yarn_resourcemanager_fs_state_store_uri']
    $resourcemanager_hosts                    = $hadoop_config['resourcemanager_hosts']
    $namenode_hosts                           = $hadoop_config['namenode_hosts']
    $journalnode_hosts                        = $hadoop_config['journalnode_hosts']
    $hadoop_var_directory                     = $hadoop_config['hadoop_var_directory']
    $datanode_volumes_failed_tolerated        = $hadoop_config['datanode_volumes_failed_tolerated']
    $dfs_namenode_handler_count               = $hadoop_config['dfs_namenode_handler_count']
    $dfs_namenode_service_handler_count       = $hadoop_config['dfs_namenode_service_handler_count']
    $dfs_namenode_service_port                = $hadoop_config['dfs_namenode_service_port']
    $dfs_block_size                           = $hadoop_config['dfs_block_size']
    $yarn_heapsize                            = $hadoop_config['yarn_heapsize']
    $yarn_nodemanager_opts                    = $hadoop_config['yarn_nodemanager_opts']
    $yarn_resourcemanager_opts                = $hadoop_config['yarn_resourcemanager_opts']
    $hadoop_heapsize                          = $hadoop_config['hadoop_heapsize']
    $hadoop_datanode_opts                     = $hadoop_config['hadoop_datanode_opts']
    $hadoop_journalnode_opts                  = $hadoop_config['hadoop_journalnode_opts']
    $hadoop_namenode_opts                     = $hadoop_config['hadoop_namenode_opts']
    $mapreduce_history_java_opts              = $hadoop_config['mapreduce_history_java_opts']
    $yarn_fair_scheduler_template             = $hadoop_config['yarn_fair_scheduler_template']
    $yarn_node_labels_enabled                 = $hadoop_config['yarn_node_labels_enabled']
    $yarn_nodemanager_resource_memory_mb      = $hadoop_config['yarn_nodemanager_os_reserved_memory_mb'] ? {
            undef   => undef,
            default => floor($facts['memorysize_mb']) - $hadoop_config['yarn_nodemanager_os_reserved_memory_mb'],
    }
    $yarn_scheduler_maximum_allocation_mb     = $hadoop_config['yarn_scheduler_maximum_allocation_mb']
    $java_home                                = $hadoop_config['java_home']


    $mapreduce_reduce_shuffle_parallelcopies  = $hadoop_config['mapreduce_reduce_shuffle_parallelcopies'] ? {
        undef   => 10,
        default => $hadoop_config['mapreduce_reduce_shuffle_parallelcopies'],
    }

    $mapreduce_task_io_sort_mb                = $hadoop_config['mapreduce_task_io_sort_mb'] ? {
        undef   => 200,
        default => $hadoop_config['mapreduce_task_io_sort_mb'],
    }
    $mapreduce_task_io_sort_factor            = $hadoop_config['mapreduce_task_io_sort_factor'] ? {
        undef   => 10,
        default => $hadoop_config['mapreduce_task_io_sort_factor'],
    }

    # Adding sane defaults to these options in case not explicitly set via hiera.
    # More info: T218758
    $yarn_resourcemanager_fs_state_store_retry_policy = $hadoop_config['yarn_resourcemanager_fs_state_store_retry_policy'] ? {
        undef   => '2000,10',
        default => $hadoop_config['yarn_resourcemanager_fs_state_store_retry_policy'],
    }

    $yarn_resourcemanager_max_completed_applications = $hadoop_config['yarn_resourcemanager_max_completed_applications'] ? {
        undef   => '5000',
        default => $hadoop_config['yarn_resourcemanager_max_completed_applications'],
    }

    $core_site_extra_properties               = $hadoop_config['core_site_extra_properties'] ? {
        undef   => {},
        default => $hadoop_config['core_site_extra_properties'],
    }
    $yarn_site_extra_properties               = $hadoop_config['yarn_site_extra_properties'] ? {
        undef   => {},
        default => $hadoop_config['yarn_site_extra_properties'],
    }
    $hdfs_site_extra_properties               = $hadoop_config['hdfs_site_extra_properties'] ? {
        undef   => {},
        default => $hadoop_config['hdfs_site_extra_properties'],
    }
    $mapred_site_extra_properties             = $hadoop_config['mapred_site_extra_properties'] ? {
        undef   => {},
        default => $hadoop_config['mapred_site_extra_properties'],
    }
    $yarn_nm_container_executor_config        = $hadoop_config['yarn_nodemanager_container_executor_config'] ? {
        undef   => {},
        default => $hadoop_config['yarn_nm_container_executor_config'],
    }

    $yarn_use_spark_shuffle                   = $hadoop_config['yarn_use_spark_shuffle'] ? {
        undef   => true,
        default => $hadoop_config['yarn_use_spark_shuffle'],
    }

    # The HDFS Trash is configured in this way:
    # 1) Once every day a checkpoint is made (that contains all the trash for a day).
    # 2) After a month a checkpoint is deleted.
    $hdfs_trash_checkpoint_interval           = $hadoop_config['hdfs_trash_checkpoint_interval'] ? {
        undef   => 1440,
        default => $hadoop_config['hdfs_trash_checkpoint_interval'],
    }
    $hdfs_trash_interval                     = $hadoop_config['hdfs_trash_interval'] ? {
        undef   => 43200,
        default => $hadoop_config['hdfs_trash_interval'],
    }

    # These Map/Reduce and YARN ApplicationMaster master settings are
    # settable per job.
    # Choosing 2G for default application container size.
    # Map container size and JVM max heap size (-XmX)
    $mapreduce_map_memory_mb                  = $hadoop_config['mapreduce_map_memory_mb'] ? {
        undef   => 2048,
        default => $hadoop_config['mapreduce_map_memory_mb'],
    }

    $mapreduce_map_java_opts                  = $hadoop_config['mapreduce_map_java_opts'] ? {
        undef   => '-Xmx1638m', # 0.8 * 2G
        default => $hadoop_config['mapreduce_map_java_opts'],
    }

    # Reduce container size and JVM max heap size (-Xmx)
    $mapreduce_reduce_memory_mb               = $hadoop_config['mapreduce_reduce_memory_mb'] ? {
        undef   => '4096', # 2 * 2G
        default => $hadoop_config['mapreduce_reduce_memory_mb'],
    }

    $mapreduce_reduce_java_opts               = $hadoop_config['mapreduce_reduce_java_opts'] ? {
        undef   => '-Xmx3276m', # 0.8 * 2 * 2G
        default => $hadoop_config['mapreduce_reduce_java_opts'],
    }

    # Yarn ApplicationMaster container size and  max heap size (-Xmx)
    $yarn_app_mapreduce_am_resource_mb        = $hadoop_config['yarn_app_mapreduce_am_resource_mb'] ? {
        undef   => 4096, # 2 * 2G
        default => $hadoop_config['yarn_app_mapreduce_am_resource_mb'],
    }

    $yarn_app_mapreduce_am_command_opts       = $hadoop_config['yarn_app_mapreduce_am_command_opts'] ? {
        undef   => '-Xmx3276m', # 0.8 * 2 * 2G
        default => $hadoop_config['yarn_app_mapreduce_am_command_opts'],
    }

    # https://issues.apache.org/jira/browse/YARN-5774
    # Flink 1.1+ also needs this value to be >= 0
    $yarn_scheduler_minimum_allocation_mb     = $hadoop_config['yarn_scheduler_minimum_allocation_mb'] ? {
        undef   => 1,
        default => $hadoop_config['yarn_scheduler_minimum_allocation_mb'],
    }

    # https://issues.apache.org/jira/browse/YARN-5774
    $yarn_scheduler_minimum_allocation_vcores  = $hadoop_config['yarn_scheduler_minimum_allocation_vcores'] ? {
        undef   => 1,
        default => $hadoop_config['yarn_scheduler_minimum_allocation_vcores'],
    }

    $yarn_scheduler_maximum_allocation_vcores  = $hadoop_config['yarn_scheduler_maximum_allocation_vcores'] ? {
        undef   => 32,
        default => $hadoop_config['yarn_scheduler_maximum_allocation_vcores'],
    }

    # Raised for T206943
    $yarn_resourcemanager_zk_timeout_ms       = $hadoop_config['yarn_resourcemanager_zk_timeout_ms'] ? {
        undef   => 20000,
        default => $hadoop_config['yarn_resourcemanager_zk_timeout_ms'],
    }

    $enable_log4j_extras                      = $hadoop_config['enable_log4j_extras'] ? {
        undef   => true,
        default => $hadoop_config['enable_log4j_extras'],
    }

    # The datanode mountpoints are retrieved from facter, among the list of mounted
    # partitions on the host. Once a partition is not available anymore (disk broken for example),
    # it is sufficient to run puppet to update the configs (and restart daemons if needed).
    $all_partitions = $facts['partitions'].map |$device, $partition_metadata| { $partition_metadata['mount'] }
    $datanode_mounts = $all_partitions.filter |$partitions| { $datanode_mounts_prefix in $partitions }

    # Fail-safe for Hadoop workers only meant to avoid running a datanode with a low number of partition by mistake.
    # The minimum number of datanode partitions is set via hiera following:
    # Number of datanode partitions - disk failures tolerated
    if $min_datanode_mounts and length($datanode_mounts) < $min_datanode_mounts {
        fail("Number of datanode mountpoints (${datanode_mounts.length}) below threshold: ${min_datanode_mounts}, please check.")
    }

    # Include Wikimedia's thirdparty/bigtop apt component
    # as an apt source on all Hadoop hosts.
    require ::profile::bigtop::apt

    # Need Java before Hadoop is installed.
    Class['profile::java'] -> Class['profile::hadoop::common']

    $hadoop_name_directory                    = "${hadoop_var_directory}/name"
    $hadoop_data_directory                    = "${hadoop_var_directory}/data"
    $hadoop_journal_directory                 = "${hadoop_var_directory}/journal"

    $zookeeper_hosts = keys($zookeeper_clusters[$zookeeper_cluster_name]['hosts'])

    # If specified, this will be rendered into the net-topology.py.erb script.
    $net_topology = $hadoop_config['net_topology']
    $net_topology_script_content = $net_topology ? {
        undef   => undef,
        default => template('profile/hadoop/net-topology.py.erb'),
    }

    $core_site_extra_properties_default = {
        'hadoop.ssl.enabled.protocols' => 'TLSv1.2',
        'hadoop.rpc.protection' => 'privacy',
        'hadoop.security.authentication' => 'kerberos',
        # https://www.cloudera.com/documentation/enterprise/5-16-x/topics/cdh_sg_hiveserver2_security.html#concept_vxf_pgx_nm
        'hadoop.proxyuser.hive.hosts' => '*',
        'hadoop.proxyuser.hive.groups' => '*',
        'hadoop.proxyuser.oozie.hosts' => '*',
        'hadoop.proxyuser.oozie.groups' => '*',
        'hadoop.proxyuser.presto.hosts' => '*',
        'hadoop.proxyuser.presto.groups' => '*',
        'hadoop.proxyuser.superset.hosts' => '*',
        'hadoop.proxyuser.superset.groups' =>'*',
        'fs.permissions.umask-mode' => '027',
    }

    $yarn_site_extra_properties_default = {
        # After upgrading to CDH 5.4.0, we are encountering this bug:
        # https://issues.apache.org/jira/browse/MAPREDUCE-5799
        # This should work around the problem.
        'yarn.app.mapreduce.am.env' => 'LD_LIBRARY_PATH=/usr/lib/hadoop/lib/native',
        # The default of 90.0 for this was marking older dells as unhealthy when they still
        # had 2TB of space left.  99% will mark them at unhealthy with they still have
        # > 200G free.
        'yarn.nodemanager.disk-health-checker.max-disk-utilization-per-disk-percentage' => '99.0',
        'yarn.resourcemanager.principal' => 'yarn/_HOST@WIKIMEDIA',
        'yarn.nodemanager.principal' => 'yarn/_HOST@WIKIMEDIA',
        'yarn.resourcemanager.keytab' => '/etc/security/keytabs/hadoop/yarn.keytab',
        'yarn.nodemanager.keytab' => '/etc/security/keytabs/hadoop/yarn.keytab',
        'yarn.nodemanager.linux-container-executor.group' => 'yarn',
        'yarn.nodemanager.container-executor.class' => 'org.apache.hadoop.yarn.server.nodemanager.LinuxContainerExecutor',
        'spark.authenticate' => true,
        'spark.network.crypto.enabled' => true,
        # We tried to bump the yarn.nodemanager.vmem-pmem-ratio to 10.1 in T278441,
        # but in several use cases Spark containers were killed due to excessive vmem usage
        # (but not the same for pmem). Bumping the ratio even more is not productive,
        # it is more efficient to just disable the vmem check.
        'yarn.nodemanager.vmem-check-enabled' => false,
    }

    $yarn_nodemanager_container_executor_config_default = {
        'yarn.nodemanager.linux-container-executor.group' => 'yarn',
        'min.user.id' => '100',
        # hdfs is allowed to make distCP working (mapred user that can be started by hdfs
        # to be able to avoid permission issues while copying).
        'allowed.system.users' => 'hive,hdfs',
        'banned.users' => 'root,yarn,mapred,bin,nobody',
    }

    $hdfs_site_extra_properties_default = {
        'dfs.cluster.administrators' => 'hdfs analytics-admins,ops',
        'dfs.block.access.token.enable' => 'true',
        'dfs.namenode.keytab.file' => '/etc/security/keytabs/hadoop/hdfs.keytab',
        'dfs.secondary.namenode.keytab.file' => '/etc/security/keytabs/hadoop/hdfs.keytab',
        'dfs.namenode.kerberos.principal' => 'hdfs/_HOST@WIKIMEDIA',
        'dfs.secondary.namenode.kerberos.principal' => 'hdfs/_HOST@WIKIMEDIA',
        'dfs.journalnode.keytab.file' => '/etc/security/keytabs/hadoop/hdfs.keytab',
        'dfs.journalnode.kerberos.principal' => 'hdfs/_HOST@WIKIMEDIA',
        'dfs.journalnode.kerberos.internal.spnego.principal' => 'HTTP/_HOST@WIKIMEDIA',
        'dfs.web.authentication.kerberos.keytab' => '/etc/security/keytabs/hadoop/HTTP.keytab',
        'dfs.web.authentication.kerberos.principal' => 'HTTP/_HOST@WIKIMEDIA',
        'dfs.datanode.keytab.file' => '/etc/security/keytabs/hadoop/hdfs.keytab',
        'dfs.datanode.kerberos.principal' => 'hdfs/_HOST@WIKIMEDIA',
        'dfs.encrypt.data.transfer' => 'true',
        'dfs.data.transfer.protection' => 'privacy',
        # This is required to allow the datanode to start:
        # https://hadoop.apache.org/docs/r2.6.0/hadoop-project-dist/hadoop-common/SecureMode.html#Secure_DataNode
        'dfs.http.policy' => 'HTTPS_ONLY',
        'dfs.encrypt.data.transfer.cipher.suites' => 'AES/CTR/NoPadding',
        'dfs.encrypt.data.transfer.cipher.key.bitlength' => '128',
    }

    $mapred_site_extra_properties_default = {
        'mapreduce.ssl.enabled' => true,
        'mapreduce.shuffle.ssl.enabled' => true,
        'mapreduce.jobhistory.principal' => 'mapred/_HOST@WIKIMEDIA',
        'mapreduce.jobhistory.keytab' => '/etc/security/keytabs/hadoop/mapred.keytab',
    }

    class { 'bigtop::hadoop':
        # Default to using running resourcemanager on the same hosts
        # as the namenodes.
        resourcemanager_hosts                            => $resourcemanager_hosts,
        zookeeper_hosts                                  => $zookeeper_hosts,
        yarn_resourcemanager_zk_timeout_ms               => $yarn_resourcemanager_zk_timeout_ms,
        yarn_resourcemanager_zk_state_store_parent_path  => $yarn_resourcemanager_zk_state_store_parent_path,
        yarn_resourcemanager_fs_state_store_uri          => $yarn_resourcemanager_fs_state_store_uri,
        yarn_resourcemanager_fs_state_store_retry_policy => $yarn_resourcemanager_fs_state_store_retry_policy,
        yarn_resourcemanager_max_completed_applications  => $yarn_resourcemanager_max_completed_applications,
        dfs_name_dir                                     => [$hadoop_name_directory],
        dfs_journalnode_edits_dir                        => $hadoop_journal_directory,
        dfs_datanode_failed_volumes_tolerated            => $datanode_volumes_failed_tolerated,
        fs_trash_checkpoint_interval                     => $hdfs_trash_checkpoint_interval,
        fs_trash_interval                                => $hdfs_trash_interval,
        dfs_namenode_handler_count                       => $dfs_namenode_handler_count,
        dfs_namenode_service_handler_count               => $dfs_namenode_service_handler_count,
        dfs_namenode_service_port                        => $dfs_namenode_service_port,

        cluster_name                                     => $cluster_name,
        namenode_hosts                                   => $namenode_hosts,
        journalnode_hosts                                => $journalnode_hosts,

        datanode_mounts                                  => $datanode_mounts,

        yarn_heapsize                                    => $yarn_heapsize,
        hadoop_heapsize                                  => $hadoop_heapsize,

        yarn_nodemanager_opts                            => $yarn_nodemanager_opts,
        yarn_resourcemanager_opts                        => $yarn_resourcemanager_opts,
        hadoop_namenode_opts                             => $hadoop_namenode_opts,
        hadoop_datanode_opts                             => $hadoop_datanode_opts,
        hadoop_journalnode_opts                          => $hadoop_journalnode_opts,
        mapreduce_history_java_opts                      => $mapreduce_history_java_opts,

        yarn_app_mapreduce_am_resource_mb                => $yarn_app_mapreduce_am_resource_mb,
        yarn_app_mapreduce_am_command_opts               => $yarn_app_mapreduce_am_command_opts,
        yarn_nodemanager_resource_memory_mb              => $yarn_nodemanager_resource_memory_mb,
        yarn_scheduler_minimum_allocation_mb             => $yarn_scheduler_minimum_allocation_mb,
        yarn_scheduler_maximum_allocation_mb             => $yarn_scheduler_maximum_allocation_mb,
        yarn_scheduler_minimum_allocation_vcores         => $yarn_scheduler_minimum_allocation_vcores,
        yarn_scheduler_maximum_allocation_vcores         => $yarn_scheduler_maximum_allocation_vcores,
        yarn_use_spark_shuffle                           => $yarn_use_spark_shuffle,
        yarn_node_labels_enabled                         => $yarn_node_labels_enabled,

        dfs_block_size                                   => 268435456, # 256 MB
        io_file_buffer_size                              => 131072,

        # Turn on Snappy compression by default for maps and final outputs
        mapreduce_intermediate_compression_codec         => 'org.apache.hadoop.io.compress.SnappyCodec',
        mapreduce_output_compression                     => true,
        mapreduce_output_compression_codec               => 'org.apache.hadoop.io.compress.SnappyCodec',
        mapreduce_output_compression_type                => 'BLOCK',

        mapreduce_job_reuse_jvm_num_tasks                => 1,

        mapreduce_reduce_shuffle_parallelcopies          => $mapreduce_reduce_shuffle_parallelcopies,
        mapreduce_task_io_sort_mb                        => $mapreduce_task_io_sort_mb,
        mapreduce_task_io_sort_factor                    => $mapreduce_task_io_sort_factor,
        mapreduce_map_memory_mb                          => $mapreduce_map_memory_mb,
        mapreduce_map_java_opts                          => $mapreduce_map_java_opts,
        mapreduce_reduce_memory_mb                       => $mapreduce_reduce_memory_mb,
        mapreduce_reduce_java_opts                       => $mapreduce_reduce_java_opts,

        net_topology_script_content                      => $net_topology_script_content,

        # This needs to be set in order to use Impala
        dfs_datanode_hdfs_blocks_metadata_enabled        => true,

        # Whether or not to use fair-scheduler.xml.erb to define FairScheduler queues.
        fair_scheduler_template                          => $yarn_fair_scheduler_template,

        # Yarn App Master possible port ranges
        yarn_app_mapreduce_am_job_client_port_range      => '55000-55199',

        core_site_extra_properties                       => $core_site_extra_properties_default + $core_site_extra_properties,
        yarn_site_extra_properties                       => $yarn_site_extra_properties_default + $yarn_site_extra_properties,
        hdfs_site_extra_properties                       => $hdfs_site_extra_properties_default + $hdfs_site_extra_properties,
        mapred_site_extra_properties                     => $mapred_site_extra_properties_default + $mapred_site_extra_properties,

        yarn_nodemanager_container_executor_config       => $yarn_nodemanager_container_executor_config_default + $yarn_nm_container_executor_config,

        java_home                                        => $java_home,
        enable_log4j_extras                              => $enable_log4j_extras,
    }

    # The following code deploys TLS certificates to the Hadoop cluster hosts.
    # Very important note too keep in mind:
    # "Ensure that common name (CN) matches exactly with the fully qualified domain name (FQDN) of the server.
    # The client compares the CN with the DNS domain name to ensure
    # that it is indeed connecting to the desired server, not the malicious one."
    # Source: https://it.hortonworks.com/blog/deploying-https-hdfs/
    # When 'ensure_ssl_config' is set to true, the following assumptions are made for
    # the puppet private repository:
    # 1) TLS certificates are not needed since we use the host's puppet ones.
    # 2) There is puppet code that copies the host's puppet TLS cert into a pks12 keystore (with custom
    #    password, see below) to a known location.
    # 3) keystores/trustores are all encrypted with the passwords stated in the $hadoop_clusters_secrets
    #    hash (stored in the private repo as well).
    # Also please remember that the configuration below takes care of deploying the trustores/keystores and
    # the related ssl-(client|server).xml configs, but it does not enable any TLS setting for Yarn/HDFS.
    # In order to do it, specific settings to the main hadoop_clusters hiera config need to be made.
    #
    if $ensure_ssl_config {

        $hadoop_ssl_config_name = "hadoop_${cluster_name}"

        $hostname_suffix = $::realm ? {
            'labs'  => '.eqiad.wmflabs',
            default => "${::site}.wmnet",
        }

        $keystore_type = 'pkcs12'
        $keystore_password = $hadoop_secrets_config['ssl_keystore_password']
        # The keystore password is needed for the Journalnode to start,
        # since not adding it or using an empty value lead to null pointer
        # exceptions. Even if the key in the keystore is not pretected by a password,
        # the setting needs to be present anyway. Upstream tutorials suggest to
        # put this value equal to the value of the keystore password.
        $keystore_keypassword = $hadoop_secrets_config['ssl_keystore_keypassword']
        $keystore_path = "${bigtop::hadoop::config_directory}/ssl/server.p12"

        # TODO: consider using profile::pki::get_cert
        puppet::expose_agent_certs{$bigtop::hadoop::config_directory:
            user         => 'root',
            group        => 'hadoop',
            provide_p12  => true,
            provide_pem  => false,
            p12_password => $keystore_password,
        }

        $ssl_server_config = {
            'ssl.server.keystore.type' => $keystore_type,
            'ssl.server.keystore.keypassword' => $keystore_keypassword,
            'ssl.server.keystore.password' => $keystore_password,
            'ssl.server.keystore.location' => $keystore_path,
        }

        # By default we ensure that the puppet CA is trusted in the default
        # JVM's truststore. No need for ssl-client.xml config in this case.
        class { 'bigtop::hadoop::ssl_config':
            config_directory  => $::bigtop::hadoop::config_directory,
            ssl_server_config => $ssl_server_config,
        }

    }

    # Starting with Bullseye the systemd unit for systemd-logind uses ProtectSystem=strict,
    # which doesn't work with HDFS, so exclude /mnt from the list of inaccessible paths for
    # the systemd-logind service
    if debian::codename::ge('bullseye') {
        systemd::unit { 'systemd-logind.service':
            content  => "[Service]\nInaccessiblePaths=-/mnt\n",
            restart  => false,
            override => true,
        }
    }

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
            before => Class['bigtop::hadoop'],
        }
    }
    contain 'bigtop::hadoop'
}
