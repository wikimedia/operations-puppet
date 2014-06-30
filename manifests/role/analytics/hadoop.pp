 # role/analytics/hadoop.pp
#
# Role classes for Analytics Hadoop nodes.
# These role classes will configure Hadoop properly in either
# the Analytics labs or Analytics production environments.

#
# Usage:
#
# To install only hadoop client packages and configs:
#   include role::analytics::hadoop
#
# To install a Hadoop Master (NameNode + ResourceManager, etc.):
#   include role::analytics::hadoop::master
#
# To install a Hadoop Worker (DataNode + NodeManager + etc.):
#   include role::analytics::hadoop::worker
#


# == Class role::analytics::hadoop
# Installs base configs for Hadoop nodes
#
class role::analytics::hadoop::client {
    # need java before hadoop is installed
    if (!defined(Package['openjdk-7-jdk'])) {
        package { 'openjdk-7-jdk':
            ensure => 'installed',
        }
    }

    # include common labs or production hadoop configs
    # based on $::realm
    if ($::realm == 'labs') {
        include role::analytics::hadoop::labs
        $ganglia_host = 'aggregator.eqiad.wmflabs'
        $ganglia_port = 50090

        # Currently in transition between using cdh (CDH5) module
        # and cdh4 module.  Labs uses cdh.
        $cdh_module_name = 'cdh'
    }
    else {
        include role::analytics::hadoop::production
        # TODO: use variables from new ganglia module once it is finished.
        $ganglia_host = '239.192.1.32'
        $ganglia_port = 8649

        # Currently in transition between using cdh (CDH5) module
        # and cdh4 module.  Production uses cdh4.
        $cdh_module_name = 'cdh4'
    }


}

# == Class role::analytics::hadoop::master
# Includes cdh4::hadoop::master classes
#
class role::analytics::hadoop::master inherits role::analytics::hadoop::client {
    system::role { 'role::analytics::hadoop::master': description => 'Hadoop Master (NameNode & ResourceManager)' }

    class { "${cdh_module_name}::hadoop::master": }

    # Icinga process alerts for NameNode, ResourceManager and HistoryServer
    nrpe::monitor_service { 'hadoop-hdfs-namenode':
        description  => 'Hadoop Namenode - Primary',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.server.namenode.NameNode"',
        require      => Class["${cdh_module_name}::hadoop::master"],
    }
    nrpe::monitor_service { 'hadoop-yarn-resourcemanager':
        description  => 'Hadoop ResourceManager',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.yarn.server.resourcemanager.ResourceManager"',
        require      => Class["${cdh_module_name}::hadoop::master"],
    }
    nrpe::monitor_service { 'hadoop-mapreduce-historyserver':
        description  => 'Hadoop HistoryServer',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.mapreduce.v2.hs.JobHistoryServer"',
        require      => Class["${cdh_module_name}::hadoop::master"],
    }
    # Alert if this NameNode is not active
    monitor_ganglia { 'hadoop-hdfs-namenode-primary-is-active':
        description => 'Hadoop NameNode Primary Is Active',
        metric      => 'Hadoop.NameNode.FSNamesystem.tag_HAState',
        warning     => '\!active',
        critical    => '\!active',
        require      => Class["${cdh_module_name}::hadoop::master"],
    }

    # Hadoop nodes are spread across multiple rows
    # and need to be able to send multicast packets
    # multiple network hops.  Hadoop GangliaContext
    # does not support this.  See:
    # https://issues.apache.org/jira/browse/HADOOP-10181
    # We use jmxtrans instead.

    # Use jmxtrans for sending metrics to ganglia
    class { "${cdh_module_name}::hadoop::jmxtrans::master":
        ganglia => "${ganglia_host}:${ganglia_port}",
    }

    # monitor disk statistics
    ganglia::plugin::python { 'diskstat': }

    # FairScheduler is creating event logs in hadoop.log.dir/fairscheduler/
    # It rotates them but does not delete old ones.  Set up cronjob to
    # delete old files in this directory.
    cron { 'hadoop-clean-fairscheduler-event-logs':
        command => 'test -d /var/log/hadoop-yarn/fairscheduler && /usr/bin/find /var/log/hadoop-yarn/fairscheduler -type f -mtime +14 -exec rm {} >/dev/null \;',
        minute  => 5,
        hour    => 0,
        require => Class["${cdh_module_name}::hadoop::master"],
    }
}

# == Class role::analytics::hadoop::worker
# Includes cdh4::hadoop::worker classes
class role::analytics::hadoop::worker inherits role::analytics::hadoop::client {
    system::role { 'role::analytics::hadoop::worker': description => 'Hadoop Worker (DataNode & NodeManager)' }

    class { "${cdh_module_name}::hadoop::worker": }

    # Icinga process alerts for DataNode and NodeManager
    nrpe::monitor_service { 'hadoop-hdfs-datanode':
        description  => 'Hadoop DataNode',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.server.datanode.DataNode"',
        require      => Class["${cdh_module_name}::hadoop::worker"],
    }
    nrpe::monitor_service { 'hadoop-yarn-nodemanager':
        description  => 'Hadoop NodeManager',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.yarn.server.nodemanager.NodeManager"',
        require      => Class["${cdh_module_name}::hadoop::worker"],
    }

    # Hadoop nodes are spread across multiple rows
    # and need to be able to send multicast packets
    # multiple network hops.  Hadoop GangliaContext
    # does not support this.  See:
    # https://issues.apache.org/jira/browse/HADOOP-10181
    # We use jmxtrans instead.

    # Use jmxtrans for sending metrics to ganglia
    class { "${cdh_module_name}::hadoop::jmxtrans::worker":
        ganglia => "${ganglia_host}:${ganglia_port}",
    }

    # monitor disk statistics
    ganglia::plugin::python { 'diskstat': }
}

# == Class role::analytics::hadoop::standby
# Include standby namenode classes
class role::analytics::hadoop::standby inherits role::analytics::hadoop::client {
    system::role { 'role::analytics::hadoop::standby': description => 'Hadoop Standby NameNode' }
    class { "${cdh_module_name}::hadoop::namenode::standby": }

    # Icinga process alert for Stand By NameNode
    nrpe::monitor_service { 'hadoop-hdfs-namenode':
        description  => 'Hadoop Namenode - Stand By',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.server.namenode.NameNode"',
        require      => Class["${cdh_module_name}::hadoop::namenode::standby"],
    }

    # Use jmxtrans for sending metrics to ganglia
    class { "${cdh_module_name}::hadoop::jmxtrans::namenode":
        ganglia => "${ganglia_host}:${ganglia_port}",
    }

    # monitor disk statistics
    ganglia::plugin::python { 'diskstat': }
}


### The following classes should not be included directly.
### You should either include role::analytics::hadoop::client,
### or role::analytics::hadoop::worker or
### role::analytics::hadoop::master.


# == Class role::analytics::hadoop::production
# Common hadoop configs for the production Kraken cluster
#
class role::analytics::hadoop::production {
    # This is the logical name of the Analytics Hadoop cluster.
    $nameservice_id           = 'kraken'

    $namenode_hosts           = [
        'analytics1010.eqiad.wmnet',
        'analytics1009.eqiad.wmnet',
    ]
    # I'm not sure if running JournalNodes
    # on DataNode hosts is a good or bad idea.
    # Doing this here now for lack of a better place.
    $journalnode_hosts        = [
        'analytics1011.eqiad.wmnet',  # Row A2
        'analytics1013.eqiad.wmnet',  # Row A2
        'analytics1014.eqiad.wmnet',  # Row C7
        'analytics1019.eqiad.wmnet',  # Row D2
        'analytics1020.eqiad.wmnet',  # Row D2
    ]

    $hadoop_name_directory    = '/var/lib/hadoop/name'
    $hadoop_data_directory    = '/var/lib/hadoop/data'
    $hadoop_journal_directory = '/var/lib/hadoop/journal'

    $datanode_mounts = [
        "$hadoop_data_directory/c",
        "$hadoop_data_directory/d",
        "$hadoop_data_directory/e",
        "$hadoop_data_directory/f",
        "$hadoop_data_directory/g",
        "$hadoop_data_directory/h",
        "$hadoop_data_directory/i",
        "$hadoop_data_directory/j",
        "$hadoop_data_directory/k",
        "$hadoop_data_directory/l"
    ]

    class { 'cdh4::hadoop':
        namenode_hosts                           => $namenode_hosts,
        nameservice_id                           => $nameservice_id,
        journalnode_hosts                        => $journalnode_hosts,
        datanode_mounts                          => $datanode_mounts,
        dfs_name_dir                             => [$hadoop_name_directory],
        dfs_journalnode_edits_dir                => $hadoop_journal_directory,
        dfs_block_size                           => 268435456,  # 256 MB
        io_file_buffer_size                      => 131072,
        # Turn on Snappy compression by default for maps and final outputs
        mapreduce_intermediate_compression       => true,
        mapreduce_intermediate_compression_codec => 'org.apache.hadoop.io.compress.SnappyCodec',
        mapreduce_output_compression             => true,
        mapreduce_output_compression_codec       => 'org.apache.hadoop.io.compress.SnappyCodec',
        mapreduce_output_compression_type        => BLOCK,
        mapreduce_map_tasks_maximum              => ($::processorcount - 2) / 2,
        mapreduce_reduce_tasks_maximum           => ($::processorcount - 2) / 2,
        mapreduce_job_reuse_jvm_num_tasks        => 1,
        mapreduce_map_memory_mb                  => 1536,
        mapreduce_reduce_memory_mb               => 3072,
        mapreduce_map_java_opts                  => '-Xmx1024M',
        mapreduce_reduce_java_opts               => '-Xmx2560M',
        mapreduce_reduce_shuffle_parallelcopies  => 10,
        mapreduce_task_io_sort_mb                => 200,
        mapreduce_task_io_sort_factor            => 10,
        yarn_nodemanager_resource_memory_mb      => 40960,
        yarn_resourcemanager_scheduler_class     => 'org.apache.hadoop.yarn.server.resourcemanager.scheduler.fair.FairScheduler',
        # use net-topology.py.erb to map hostname to /datacenter/rack/row id.
        net_topology_script_template             => 'hadoop/net-topology.py.erb',
    }

    file { "$::cdh4::hadoop::config_directory/fair-scheduler.xml":
        content => template('hadoop/fair-scheduler.xml.erb'),
        require => Class['cdh4::hadoop'],
    }
    file { "$::cdh4::hadoop::config_directory/fair-scheduler-allocation.xml":
        content => template('hadoop/fair-scheduler-allocation.xml.erb'),
        require => Class['cdh4::hadoop'],
    }

    # If the current node is a journalnode, then
    # go ahead and include an icinga alert for the
    # JournalNode process.
    if member($journalnode_hosts, $::fqdn) {
        nrpe::monitor_service { 'hadoop-hdfs-journalnode':
            description  => 'Hadoop JournalNode',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.qjournal.server.JournalNode"',
            require      => Class["${cdh_module_name}::hadoop"],
        }
    }
}





# == Class role::analytics::hadoop::labs
# Common hadoop configs for the spawning Hadoop
# clusters in labs.  Since labs instances are
# configured via global variables, you'll
# need to make sure the following are set via
# the Manage Instances GUI.
#
# $hadoop_namenodes   - Comma separated list of FQDNs that should be NameNodes
#                       for this cluster.  The first entry in the list
#                       is assumed to be the preferred primary NameNode.
# $journalnode_hosts  - Comma separated list of FQDNs that should be JournalNodes
#                       for this cluster.
# $cluster_name       - Logical name of this cluster.  This will be used
#                       as the Hadoop Nameservice ID.
# $heapsize           - Optional.  Set this to a value in MB to limit the JVM
#                       heapsize for all Hadoop daemons.
#
class role::analytics::hadoop::labs {
    # if the global variable $::hadoop_namenodes is set,
    # use it as the namenode_hostnames.  This allows
    # configuration via the Labs Instance configuration page.
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

    $hadoop_name_directory    = '/var/lib/hadoop/name'

    $hadoop_data_directory    = '/var/lib/hadoop/data'
    $datanode_mounts = [
        "$hadoop_data_directory/a",
        "$hadoop_data_directory/b",
    ]

    $hadoop_journal_directory = '/var/lib/hadoop/journal'

    # We don't have to create any partions in labs, so it
    # is unlikely that /var/lib/hadoop and $hadoop_data_directory
    # will be created manually. Ensure it and datanode_mounts exist.
    file { ['/var/lib/hadoop', $hadoop_data_directory]:
        ensure => 'directory',
    }

    class { 'cdh::hadoop':
        cluster_name                             => $cluster_name,
        namenode_hosts                           => $namenode_hosts,
        journalnode_hosts                        => $journalnode_hosts,
        datanode_mounts                          => $datanode_mounts,
        dfs_name_dir                             => [$hadoop_name_directory],
        dfs_journalnode_edits_dir                => $hadoop_journal_directory,
        dfs_block_size                           => 268435456,  # 256 MB
        io_file_buffer_size                      => 131072,
        # Turn on Snappy compression by default for maps and final outputs
        mapreduce_intermediate_compression       => true,
        mapreduce_intermediate_compression_codec => 'org.apache.hadoop.io.compress.SnappyCodec',
        mapreduce_output_compression             => true,
        mapreduce_output_compression_codec       => 'org.apache.hadoop.io.compress.SnappyCodec',
        mapreduce_output_compression_type        => BLOCK,
        mapreduce_map_tasks_maximum              => 2,
        mapreduce_reduce_tasks_maximum           => 2,
        mapreduce_job_reuse_jvm_num_tasks        => 1,
        hadoop_heapsize                          => $heapsize,
        yarn_heapsize                            => $heapsize,
    }
}


