 # role/analytics/hadoop.pp
#
# Role classes for Analytics Hadoop nodes.
# These role classes will configure Hadoop properly in either
# the Labs or Production environments.
#
#
# Production configs are hardcoded here.  Labs has a few parameters
# that need to be specified as global variables via the Manage Instances GUI:
#
# $cluster_name       - Logical name of this cluster.  Required.
#
# $hadoop_namenodes   - Comma separated list of FQDNs that should be NameNodes
#                       for this cluster.  The first entry in the list
#                       is assumed to be the preferred primary NameNode.  Required.
#
# $journalnode_hosts  - Comma separated list of FQDNs that should be JournalNodes
#                       for this cluster.  Optional.  If not specified, HA will not be configured.
#
# $heapsize           - Optional.  Set this to a value in MB to limit the JVM
#                       heapsize for all Hadoop daemons.  Optional.
#
#
# Usage:
#
# To install only hadoop client packages and configs:
#   include role::analytics::hadoop::client
#
# To install a Hadoop Master (NameNode + ResourceManager, etc.):
#   include role::analytics::hadoop::master
#
# To install a Hadoop Worker (DataNode + NodeManager + etc.):
#   include role::analytics::hadoop::worker
#

# == Class role::analytics::hadoop::config
# This is just a config class.  You can include this
# anywhere if you need to infer Hadoop configs.  It
# only sets variables, it will not install or configure
# any packages.  hadoop::client inherits from this class.
#
class role::analytics::hadoop::config {

    # Configs common to both Production and Labs.
    $hadoop_var_directory                     = '/var/lib/hadoop'
    $hadoop_name_directory                    = "${hadoop_var_directory}/name"
    $hadoop_data_directory                    = "${hadoop_var_directory}/data"
    $hadoop_journal_directory                 = "${hadoop_var_directory}/journal"
    $dfs_block_size                           = 268435456  # 256 MB
    $io_file_buffer_size                      = 131072
    # Turn on Snappy compression by default for maps and final outputs
    $mapreduce_intermediate_compression_codec = 'org.apache.hadoop.io.compress.SnappyCodec'
    $mapreduce_output_compression             = true
    $mapreduce_output_compression_codec       = 'org.apache.hadoop.io.compress.SnappyCodec'
    $mapreduce_output_compression_type        = 'BLOCK'
    $mapreduce_job_reuse_jvm_num_tasks        = 1
    $fair_scheduler_template                  = 'hadoop/fair-scheduler.xml.erb'
    # setting this to false or undef interferes with defining it within a node
    $gelf_logging_enabled                     = true


    # Configs specific to Production.
    if $::realm == 'production' {
        # This is the logical name of the Analytics Hadoop cluster.
        $cluster_name             = 'analytics-hadoop'

        $namenode_hosts           = [
            'analytics1010.eqiad.wmnet',
            'analytics1004.eqiad.wmnet',
        ]
        # JournalNodes are colocated on worker DataNodes.
        $journalnode_hosts        = [
            'analytics1011.eqiad.wmnet',  # Row A2
            'analytics1028.eqiad.wmnet',  # Row C2
            'analytics1019.eqiad.wmnet',  # Row D2
        ]

        # analytics1011-analytics1020 have 12 mounts on disks sda - sdl.
        if $::hostname =~ /analytics10(1[1-9]|20)/ {
            $datanode_mounts = [
                "${hadoop_data_directory}/a",
                "${hadoop_data_directory}/b",
                "${hadoop_data_directory}/c",
                "${hadoop_data_directory}/d",
                "${hadoop_data_directory}/e",
                "${hadoop_data_directory}/f",
                "${hadoop_data_directory}/g",
                "${hadoop_data_directory}/h",
                "${hadoop_data_directory}/i",
                "${hadoop_data_directory}/j",
                "${hadoop_data_directory}/k",
                "${hadoop_data_directory}/l",
            ]
        }
        # analytics1028-analytics1041 have mounts on disks sdb - sdm.
        # (sda is hardware raid on the 2 2.5 drives in the flex bays.)
        else {
            $datanode_mounts = [
                "${hadoop_data_directory}/b",
                "${hadoop_data_directory}/c",
                "${hadoop_data_directory}/d",
                "${hadoop_data_directory}/e",
                "${hadoop_data_directory}/f",
                "${hadoop_data_directory}/g",
                "${hadoop_data_directory}/h",
                "${hadoop_data_directory}/i",
                "${hadoop_data_directory}/j",
                "${hadoop_data_directory}/k",
                "${hadoop_data_directory}/l",
                "${hadoop_data_directory}/m",
            ]
        }

        $mapreduce_map_tasks_maximum              = ($::processorcount - 2) / 2
        $mapreduce_reduce_tasks_maximum           = ($::processorcount - 2) / 2

        $mapreduce_reduce_shuffle_parallelcopies  = 10
        $mapreduce_task_io_sort_mb                = 200
        $mapreduce_task_io_sort_factor            = 10


        # Configure memory based on these recommendations:
        # http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.6.0/bk_installing_manually_book/content/rpm-chap1-11.html

        # Select a 'reserve' memory size for the
        # OS and other Hadoop processes.
        if $::memorysize_mb <= 4096 {
            $reserve_memory_mb = 1024
        }
        elsif $::memorysize_mb <= 16384 {
            $reserve_memory_mb = 2048
        }
        elsif $::memorysize_mb <= 24576 {
            $reserve_memory_mb = 4096
        }
        elsif $::memorysize_mb <= 49152 {
            $reserve_memory_mb = 6144
        }
        elsif $::memorysize_mb <= 73728 {
            $reserve_memory_mb = 8192
        }
        elsif $::memorysize_mb <= 98304 {
            $reserve_memory_mb = 12288
        }
        elsif $::memorysize_mb <= 131072 {
            $reserve_memory_mb = 24576
        }
        elsif $::memorysize_mb <= 262144 {
            $reserve_memory_mb = 32768
        }
        else {
            $reserve_memory_mb = 65536
        }

        # Memory available for use by Hadoop jobs.
        $available_memory_mb = $::memorysize_mb - $reserve_memory_mb

        # Using + 0 here ensures that these variables are
        # integers (Fixnums) and won't throw errors
        # when used with min()/max() functions.
        if $available_memory_mb <= 4096 {
            $min_container_size_mb = 256 + 0
        }
        elsif $available_memory_mb <= 8192 {
            $min_container_size_mb = 512 + 0
        }
        elsif $available_memory_mb <= 24576 {
            $min_container_size_mb = 1024 + 0
        }
        else  {
            $min_container_size_mb = 2048 + 0
        }

        # number of containers = min (2*CORES, 1.8*DISKS, (Total available RAM) / MIN_CONTAINER_SIZE)
        $number_of_containers                     = floor(min(2 * $::processorcount, 1.8 * size($datanode_mounts), $available_memory_mb / $min_container_size_mb))
        # RAM-per-container = max(MIN_CONTAINER_SIZE, (Total Available RAM) / containers))
        $memory_per_container_mb                  = max($min_container_size_mb, $available_memory_mb / $number_of_containers)

        $mapreduce_map_memory_mb                  = floor($memory_per_container_mb)
        $mapreduce_reduce_memory_mb               = floor(2 * $memory_per_container_mb)
        $map_jvm_heap_size                        = floor(0.8 * $memory_per_container_mb)
        $mapreduce_map_java_opts                  = "-Xmx${map_jvm_heap_size}m"
        $reduce_jvm_heap_size                     = floor(0.8 * 2 * $memory_per_container_mb)
        $mapreduce_reduce_java_opts               = "-Xmx${reduce_jvm_heap_size}m"

        $yarn_app_mapreduce_am_resource_mb        = floor(2 * $memory_per_container_mb)
        $mapreduce_am_heap_size                   = floor(0.8 * 2 * $memory_per_container_mb)
        $yarn_app_mapreduce_am_command_opts       = "-Xmx${mapreduce_am_heap_size}m"

        $yarn_nodemanager_resource_memory_mb      = floor($number_of_containers * $memory_per_container_mb)
        $yarn_scheduler_minimum_allocation_mb     = floor($memory_per_container_mb)
        $yarn_scheduler_maximum_allocation_mb     = floor($number_of_containers * $memory_per_container_mb)

        # use net-topology.py.erb to map hostname to /datacenter/rack/row id.
        $net_topology_script_template             = 'hadoop/net-topology.py.erb'
        $hadoop_heapsize                          = undef
        $yarn_heapsize                            = undef

        # TODO: use variables from new ganglia module once it is finished.
        $ganglia_host                             = '239.192.1.32'
        $ganglia_port                             = 8649
        $gelf_logging_host                        = 'logstash1002.eqiad.wmnet'
        # In production, make sure that HDFS user directories are
        # created for everyone in these groups.
        $hadoop_users_posix_groups                = 'analytics-users analytics-privatedata-users analytics-admins'
    }

    # Configs specific to Labs.
    elsif $::realm == 'labs' {
        # These variables are configurable via the
        # Labs Manage Instances GUI.
        $namenode_hosts = $::hadoop_namenodes ? {
            undef   => [$::fqdn],
            default => split($::hadoop_namenodes, ','),
        }

        $journalnode_hosts = $::hadoop_journalnodes ? {
            undef   => undef,
            default => split($::hadoop_journalnodes, ','),
        }

        $cluster_name = $::hadoop_cluster_name ? {
            undef   => undef,
            default => $::hadoop_cluster_name,
        }

        # Allow labs users to configure their Hadoop daemon
        # Heapsize.  NOTE:  This will be applied to
        # All Hadoop related services on this node.
        $heapsize = $::hadoop_heapsize ? {
            undef   => undef,
            default => $::hadoop_heapsize,
        }

        $datanode_mounts = [
            "$hadoop_data_directory/a",
            "$hadoop_data_directory/b",
        ]

        # Limit tasks in Labs.
        $mapreduce_map_tasks_maximum              = 2
        $mapreduce_reduce_tasks_maximum           = 2

        # Labs sets these at undef, which lets the Hadoop defaults stick.
        $mapreduce_reduce_shuffle_parallelcopies  = undef
        $mapreduce_task_io_sort_mb                = undef
        $mapreduce_task_io_sort_factor            = undef
        $mapreduce_map_memory_mb                  = undef
        $mapreduce_reduce_memory_mb               = undef
        $mapreduce_map_java_opts                  = undef
        $mapreduce_reduce_java_opts               = undef
        $yarn_app_mapreduce_am_resource_mb        = undef
        $yarn_app_mapreduce_am_command_opts       = undef
        $yarn_nodemanager_resource_memory_mb      = undef
        $yarn_scheduler_minimum_allocation_mb     = undef
        $yarn_scheduler_maximum_allocation_mb     = undef
        $net_topology_script_template             = undef

        $ganglia_host                             = 'aggregator.eqiad.wmflabs'
        $ganglia_port                             = 50090
        $gelf_logging_host                        = '127.0.0.1'
        # In labs, make sure that HDFS user directories are
        # created for everyone in the project-analytics group.
        $hadoop_users_posix_groups                 = 'project-analytics'


        # Hadoop directories in labs should be automatically created.
        # This conditional could be added to each of the main classes
        # below, but since it doesn't hurt to have these directories
        # in labs, and since I don't want to add $::realm conditionals
        # below, I just create them here.
        file { [
            $hadoop_var_directory,
            $hadoop_name_directory,
            $hadoop_journal_directory,
            $hadoop_data_directory,
            $datanode_mounts,
        ]:
            ensure => 'directory',
        }
    }
}



# == Class role::analytics::hadoop
# Installs Hadoop client pacakges and configuration.
#
class role::analytics::hadoop::client inherits role::analytics::hadoop::config {
    # need java before hadoop is installed
    if (!defined(Package['openjdk-7-jdk'])) {
        package { 'openjdk-7-jdk':
            ensure => 'installed',
        }
    }

    class { 'cdh::hadoop':
        cluster_name                             => $cluster_name,
        namenode_hosts                           => $namenode_hosts,
        journalnode_hosts                        => $journalnode_hosts,
        datanode_mounts                          => $datanode_mounts,
        dfs_name_dir                             => [$hadoop_name_directory],
        dfs_journalnode_edits_dir                => $hadoop_journal_directory,
        dfs_block_size                           => $dfs_block_size,
        io_file_buffer_size                      => $io_file_buffer_size,
        mapreduce_intermediate_compression_codec => $mapreduce_intermediate_compression_codec,
        mapreduce_output_compression             => $mapreduce_output_compression,
        mapreduce_output_compression_codec       => $mapreduce_output_compression_codec,
        mapreduce_output_compression_type        => $mapreduce_output_compression_type,

        mapreduce_map_tasks_maximum              => $mapreduce_map_tasks_maximum,
        mapreduce_reduce_tasks_maximum           => $mapreduce_reduce_tasks_maximum,
        mapreduce_job_reuse_jvm_num_tasks        => $mapreduce_job_reuse_jvm_num_tasks,
        mapreduce_reduce_shuffle_parallelcopies  => $mapreduce_reduce_shuffle_parallelcopies,
        mapreduce_task_io_sort_mb                => $mapreduce_task_io_sort_mb,
        mapreduce_task_io_sort_factor            => $mapreduce_task_io_sort_factor,

        mapreduce_map_memory_mb                  => $mapreduce_map_memory_mb,
        mapreduce_reduce_memory_mb               => $mapreduce_reduce_memory_mb,
        mapreduce_map_java_opts                  => $mapreduce_map_java_opts,
        mapreduce_reduce_java_opts               => $mapreduce_reduce_java_opts,
        yarn_app_mapreduce_am_resource_mb        => $yarn_app_mapreduce_am_resource_mb,
        yarn_app_mapreduce_am_command_opts       => $yarn_app_mapreduce_am_command_opts,

        yarn_nodemanager_resource_memory_mb      => $yarn_nodemanager_resource_memory_mb,
        yarn_scheduler_minimum_allocation_mb     => $yarn_scheduler_minimum_allocation_mb,
        yarn_scheduler_maximum_allocation_mb     => $yarn_scheduler_maximum_allocation_mb,

        # Use net-topology.py.erb to map hostname to /datacenter/rack/row id.
        net_topology_script_template             => $net_topology_script_template,
        # Use fair-scheduler.xml.erb to define FairScheduler queues.
        fair_scheduler_template                  => $fair_scheduler_template,
        gelf_logging_enabled                     => $gelf_logging_enabled,
        gelf_logging_host                        => $gelf_logging_host,
        gelf_logging_port                        => $gelf_logging_port,
    }

    # If in production AND the current node is a journalnode, then
    # go ahead and include an icinga alert for the JournalNode process.
    if $::realm == 'production' and member($journalnode_hosts, $::fqdn) {
        nrpe::monitor_service { 'hadoop-hdfs-journalnode':
            description  => 'Hadoop JournalNode',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.qjournal.server.JournalNode"',
            require      => Class['cdh::hadoop'],
        }
    }
    if $gelf_logging_enabled {
        package { 'libjson-simple-java':
            ensure => 'installed',
        }
        # symlink into hadoop classpath
        file { '/usr/lib/hadoop/lib/json_simple-1.1.jar':
            ensure => 'link',
            target => '/usr/share/java/json_simple-1.1.jar',
            require => Package['libjson-simple-java'],
        }
        package { 'liblogstash-gelf-java':
            ensure => 'installed',
        }
        # symlink into hadoop classpath
        file { '/usr/lib/hadoop/lib/logstash-gelf.jar':
            ensure => 'link',
            target => '/usr/share/java/logstash-gelf.jar',
            require => Package['liblogstash-gelf-java'],
        }
    }
}



# == Class role::analytics::hadoop::master
# Includes cdh::hadoop::master classes
#
class role::analytics::hadoop::master inherits role::analytics::hadoop::client {
    system::role { 'role::analytics::hadoop::master':
        description => 'Hadoop Master (NameNode & ResourceManager)',
    }

    class { 'cdh::hadoop::master': }

    # Master should run httpfs daemon.
    class { 'cdh::hadoop::httpfs':
        require => Class['cdh::hadoop::master'],
    }

    # Hadoop nodes are spread across multiple rows
    # and need to be able to send multicast packets
    # multiple network hops.  Hadoop GangliaContext
    # does not support this.  See:
    # https://issues.apache.org/jira/browse/HADOOP-10181
    # We use jmxtrans instead.
    # Use jmxtrans for sending metrics to ganglia
    class { 'cdh::hadoop::jmxtrans::master':
        ganglia => "${ganglia_host}:${ganglia_port}",
    }

    # monitor disk statistics
    if !defined(Ganglia::Plugin::Python['diskstat']) {
        ganglia::plugin::python { 'diskstat': }
    }

    # FairScheduler is creating event logs in hadoop.log.dir/fairscheduler/
    # It rotates them but does not delete old ones.  Set up cronjob to
    # delete old files in this directory.
    cron { 'hadoop-clean-fairscheduler-event-logs':
        command => 'test -d /var/log/hadoop-yarn/fairscheduler && /usr/bin/find /var/log/hadoop-yarn/fairscheduler -type f -mtime +14 -exec rm {} >/dev/null \;',
        minute  => 5,
        hour    => 0,
        require => Class['cdh::hadoop::master'],
    }


    # Include icinga alerts if production realm.
    if $::realm == 'production' {
        # Icinga process alerts for NameNode, ResourceManager and HistoryServer
        nrpe::monitor_service { 'hadoop-hdfs-namenode':
            description  => 'Hadoop Namenode - Primary',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.server.namenode.NameNode"',
            require      => Class['cdh::hadoop::master'],
        }
        nrpe::monitor_service { 'hadoop-yarn-resourcemanager':
            description  => 'Hadoop ResourceManager',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.yarn.server.resourcemanager.ResourceManager"',
            require      => Class['cdh::hadoop::master'],
        }
        nrpe::monitor_service { 'hadoop-mapreduce-historyserver':
            description  => 'Hadoop HistoryServer',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.mapreduce.v2.hs.JobHistoryServer"',
            require      => Class['cdh::hadoop::master'],
        }
        # Alert if this NameNode is not active
        monitor_ganglia { 'hadoop-hdfs-namenode-primary-is-active':
            description => 'Hadoop NameNode Primary Is Active',
            metric      => 'Hadoop.NameNode.FSNamesystem.tag_HAState',
            warning     => '\!active',
            critical    => '\!active',
            require      => Class['cdh::hadoop::master'],
        }
    }

    # This will create HDFS user home directories
    # for all users in the provided groups.
    # This only needs to be run on the NameNode
    # where all users that want to use Hadoop
    # must have shell accounts anyway.
    class { 'cdh::hadoop::users':
        groups  => $hadoop_users_posix_groups,
        require => Class['cdh::hadoop::master'],
    }
}

# == Class role::analytics::hadoop::worker
# Includes cdh::hadoop::worker classes
class role::analytics::hadoop::worker inherits role::analytics::hadoop::client {
    system::role { 'role::analytics::hadoop::worker':
        description => 'Hadoop Worker (DataNode & NodeManager)',
    }

    class { 'cdh::hadoop::worker': }

    # Hadoop nodes are spread across multiple rows
    # and need to be able to send multicast packets
    # multiple network hops.  Hadoop GangliaContext
    # does not support this.  See:
    # https://issues.apache.org/jira/browse/HADOOP-10181
    # We use jmxtrans instead.

    # Use jmxtrans for sending metrics to ganglia
    class { 'cdh::hadoop::jmxtrans::worker':
        ganglia => "${ganglia_host}:${ganglia_port}",
    }

    # monitor disk statistics
    ganglia::plugin::python { 'diskstat': }


    # Include icinga alerts if production realm.
    if $::realm == 'production' {
        # Icinga process alerts for DataNode and NodeManager
        nrpe::monitor_service { 'hadoop-hdfs-datanode':
            description  => 'Hadoop DataNode',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.server.datanode.DataNode"',
            require      => Class['cdh::hadoop::worker'],
        }
        nrpe::monitor_service { 'hadoop-yarn-nodemanager':
            description  => 'Hadoop NodeManager',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.yarn.server.nodemanager.NodeManager"',
            require      => Class['cdh::hadoop::worker'],
        }
    }

    # Install hive client on worker nodes to get
    # hive-hcatalog package.  hive-catalog depends
    # on hive package, so we might as well
    # configure hive too.
    include role::analytics::hive::client


    # We use this to send passive checks off to icinga
    # for generating alerts.  We need the nsca-client package
    # to do this remotely.  Some oozie jobs use this,
    # and it must be present on all datanodes.
    include role::analytics::hadoop::monitor::nsca::client
}

# == Class role::analytics::hadoop::monitor::nsca::client
# This class exists in order to override the group ownership
# and permissions of the /etc/send_nsca.cfg file.  Hadoop
# processes need to be able to read this file in order to
# run send_nsca as part of Oozie submitted monitoring jobs.
class role::analytics::hadoop::monitor::nsca::client inherits icinga::monitor::nsca::client {
    File ['/etc/send_nsca.cfg'] {
        group => 'hadoop',
        mode  => '0440',
    }
}

# == Class role::analytics::hadoop::standby
# Include standby NameNode classes
#
class role::analytics::hadoop::standby inherits role::analytics::hadoop::client {
    system::role { 'role::analytics::hadoop::standby':
        description => 'Hadoop Standby NameNode',
    }

    class { 'cdh::hadoop::namenode::standby': }

    # Use jmxtrans for sending metrics to ganglia
    class { 'cdh::hadoop::jmxtrans::namenode':
        ganglia => "${ganglia_host}:${ganglia_port}",
    }

    # monitor disk statistics
    ganglia::plugin::python { 'diskstat': }

    # Include icinga alerts if production realm.
    if $::realm == 'production' {
        # Icinga process alert for Stand By NameNode
        nrpe::monitor_service { 'hadoop-hdfs-namenode':
            description  => 'Hadoop Namenode - Stand By',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.server.namenode.NameNode"',
            require      => Class['cdh::hadoop::namenode::standby'],
        }
    }
}
