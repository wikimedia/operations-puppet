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
        elsif $::hostname =~ /analytics10(2[89]|3[0-9]|4[01])/ {
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
        $mapreduce_map_memory_mb                  = 1536
        $mapreduce_reduce_memory_mb               = 3072
        $mapreduce_map_java_opts                  = '-Xmx1024M'
        $mapreduce_reduce_java_opts               = '-Xmx2560M'
        $mapreduce_reduce_shuffle_parallelcopies  = 10
        $mapreduce_task_io_sort_mb                = 200
        $mapreduce_task_io_sort_factor            = 10
        $yarn_nodemanager_resource_memory_mb      = 40960
        # use net-topology.py.erb to map hostname to /datacenter/rack/row id.
        $net_topology_script_template             = 'hadoop/net-topology.py.erb'
        $hadoop_heapsize                          = undef
        $yarn_heapsize                            = undef

        # TODO: use variables from new ganglia module once it is finished.
        $ganglia_host = '239.192.1.32'
        $ganglia_port = 8649
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
        $mapreduce_map_memory_mb                  = undef
        $mapreduce_reduce_memory_mb               = undef
        $mapreduce_map_java_opts                  = undef
        $mapreduce_reduce_java_opts               = undef
        $mapreduce_reduce_shuffle_parallelcopies  = undef
        $mapreduce_task_io_sort_mb                = undef
        $mapreduce_task_io_sort_factor            = undef
        $yarn_nodemanager_resource_memory_mb      = undef
        $net_topology_script_template             = undef

        $ganglia_host = 'aggregator.eqiad.wmflabs'
        $ganglia_port = 50090

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
        mapreduce_map_memory_mb                  => $mapreduce_map_memory_mb,
        mapreduce_reduce_memory_mb               => $mapreduce_reduce_memory_mb,
        mapreduce_map_java_opts                  => $mapreduce_map_java_opts,
        mapreduce_reduce_java_opts               => $mapreduce_reduce_java_opts,
        mapreduce_reduce_shuffle_parallelcopies  => $mapreduce_reduce_shuffle_parallelcopies,
        mapreduce_task_io_sort_mb                => $mapreduce_task_io_sort_mb,
        mapreduce_task_io_sort_factor            => $mapreduce_task_io_sort_factor,
        yarn_nodemanager_resource_memory_mb      => $yarn_nodemanager_resource_memory_mb,
        # Use net-topology.py.erb to map hostname to /datacenter/rack/row id.
        net_topology_script_template             => $net_topology_script_template,
        # Use fair-scheduler.xml.erb to define FairScheduler queues.
        fair_scheduler_template                  => $fair_scheduler_template,
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
    if !defined(Package['nsca-client']) {
        package { 'nsca-client':
            ensure => 'installed',
        }
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
