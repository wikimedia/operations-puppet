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
        package { 'openjdk-7-jdk': }
    }

    # include common labs or production hadoop configs
    # based on $::realm
    if ($::realm == 'labs') {
        include role::analytics::hadoop::labs
    }
    else {
        include role::analytics::hadoop::production
    }
}

# == Class role::analytics::hadoop::master
# Includes cdh4::hadoop::master classes
#
class role::analytics::hadoop::master inherits role::analytics::hadoop::client {
    system::role { 'role::analytics::hadoop::master': description => 'Hadoop Master (NameNode & ResourceManager)' }
    include cdh4::hadoop::master
}

# == Class role::analytics::hadoop::worker
# Includes cdh4::hadoop::worker classes
class role::analytics::hadoop::worker inherits role::analytics::hadoop::client {
    system::role { 'role::analytics::hadoop::worker': description => 'Hadoop Worker (DataNode & NodeManager)' }
    include cdh4::hadoop::worker
}

# == Class role::analytics::hadoop::standby inherits role::analytics::hadoop::client
#
class role::analytics::hadoop::standby inherits role::analytics::hadoop::client {
    system::role { 'role::analytics::hadoop::standby': description => 'Hadoop Standby NameNode' }
    include cdh4::hadoop::namenode::standby
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
        'analytics1012.eqiad.wmnet',  # Row A2 # remove this soon.
        'analytics1013.eqiad.wmnet',  # Row A2
        'analytics1014.eqiad.wmnet',  # Row C7
        # TODO: Add a Row D journalnode once Row D is available.
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
        namenode_hosts                          => $namenode_hosts,
        nameservice_id                          => $nameservice_id,
        journalnode_hosts                       => $journalnode_hosts,
        datanode_mounts                         => $datanode_mounts,
        dfs_name_dir                            => [$hadoop_name_directory],
        dfs_journalnode_edits_dir               => $hadoop_journal_directory,
        dfs_block_size                          => 268435456,  # 256 MB
        io_file_buffer_size                     => 131072,
        mapreduce_map_tasks_maximum             => ($::processorcount - 2) / 2,
        mapreduce_reduce_tasks_maximum          => ($::processorcount - 2) / 2,
        mapreduce_job_reuse_jvm_num_tasks       => 1,
        mapreduce_map_memory_mb                 => 1536,
        mapreduce_reduce_memory_mb              => 3072,
        mapreduce_map_java_opts                 => '-Xmx1024M',
        mapreduce_reduce_java_opts              => '-Xmx2560M',
        mapreduce_reduce_shuffle_parallelcopies => 10,
        mapreduce_task_io_sort_mb               => 200,
        mapreduce_task_io_sort_factor           => 10,
        yarn_nodemanager_resource_memory_mb     => 40960,
        yarn_resourcemanager_scheduler_class    => 'org.apache.hadoop.yarn.server.resourcemanager.scheduler.fair.FairScheduler',
        # TODO: use variables from new ganglia module once it is finished.
        ganglia_hosts                           => ['239.192.1.32:8649'],
        # use net-topology.py.erb to map hostname to /datacenter/rack/row id.
        net_topology_script_template            => 'hadoop/net-topology.py.erb',
    }

    file { "$::cdh4::hadoop::config_directory/fair-scheduler.xml":
        content => template('hadoop/fair-scheduler.xml.erb'),
        require => Class['cdh4::hadoop'],
    }
    file { "$::cdh4::hadoop::config_directory/fair-scheduler-allocation.xml":
        content => template('hadoop/fair-scheduler-allocation.xml.erb'),
        require => Class['cdh4::hadoop'],
    }
}





# == Class role::analytics::hadoop::labs
# Common hadoop configs for the labs Kraken cluster
# namenode_hostname is configurable via the 
# hadoop_namenode global variable, and defaults to
# this nodes $::fqdn.
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

    $nameservice_id = $::hadoop_nameservice_id ? {
        undef   => undef,
        default => $::hadoop_nameservice_id,
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

    class { 'cdh4::hadoop':
        namenode_hosts                          => $namenode_hosts,
        nameservice_id                          => $nameservice_id,
        journalnode_hosts                       => $journalnode_hosts,
        datanode_mounts                         => $datanode_mounts,
        dfs_name_dir                            => [$hadoop_name_directory],
        dfs_journalnode_edits_dir               => $hadoop_journal_directory,
        dfs_block_size                          => 268435456,  # 256 MB
        io_file_buffer_size                     => 131072,
        mapreduce_map_tasks_maximum             => 2,
        mapreduce_reduce_tasks_maximum          => 2,
        mapreduce_job_reuse_jvm_num_tasks       => 1,
        yarn_resourcemanager_scheduler_class    => 'org.apache.hadoop.yarn.server.resourcemanager.scheduler.fair.FairScheduler',
        # TODO: use variables from new ganglia module once it is finished.
        ganglia_hosts                           => ['aggregator1.pmtpa.wmflabs:50090'],
    }

    file { "$::cdh4::hadoop::config_directory/fair-scheduler.xml":
        content => template('hadoop/fair-scheduler.xml.erb'),
        require => Class['cdh4::hadoop'],
    }
    file { "$::cdh4::hadoop::config_directory/fair-scheduler-allocation.xml":
        content => template('hadoop/fair-scheduler-allocation.xml.erb'),
        require => Class['cdh4::hadoop'],
    }
}


