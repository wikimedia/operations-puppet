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
class role::analytics::hadoop {
    # need java before hadoop is installed
    require role::analytics::java

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
class role::analytics::hadoop::master inherits role::analytics::hadoop {
    system_role { 'role::analytics::hadoop::master': description => 'Hadoop Master (NameNode & ResourceManager)' }
    include cdh4::hadoop::master
}

# == Class role::analytics::hadoop::worker
# Includes cdh4::hadoop::worker classes
class role::analytics::hadoop::worker inherits role::analytics::hadoop {
    system_role { 'role::analytics::hadoop::worker': description => 'Hadoop Worker (DataNode & NodeManager)' }
    include cdh4::hadoop::worker
}


# == Class role::analytics::hadoop::production
# Common hadoop configs for the production Kraken cluster
#
class role::analytics::hadoop::production {
    $namenode_hostname        = 'analytics1010.eqiad.wmnet'
    $hadoop_name_directory    = '/var/lib/hadoop/name'

    $hadoop_data_directory    = '/var/lib/hadoop/data'
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
        namenode_hostname                       => $namenode_hostname,
        datanode_mounts                         => $datanode_mounts,
        dfs_name_dir                            => [$hadoop_name_directory],
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
#
class role::analytics::hadoop::labs {
    $namenode_hostname        = 'kraken0.pmtpa.wmflabs'
    $hadoop_name_directory    = '/var/lib/hadoop/name'

    $hadoop_data_directory    = '/var/lib/hadoop/data'
    $datanode_mounts = [
        "$hadoop_data_directory/a",
        "$hadoop_data_directory/b",
    ]

    class { 'cdh4::hadoop':
        namenode_hostname                       => $namenode_hostname,
        datanode_mounts                         => $datanode_mounts,
        dfs_name_dir                            => [$hadoop_name_directory],
        dfs_block_size                          => 268435456,  # 256 MB
        io_file_buffer_size                     => 131072,
        mapreduce_map_tasks_maximum             => 2,
        mapreduce_reduce_tasks_maximum          => 2,
        mapreduce_job_reuse_jvm_num_tasks       => 1,
        yarn_resourcemanager_scheduler_class    => 'org.apache.hadoop.yarn.server.resourcemanager.scheduler.fair.FairScheduler',
        # TODO: use variables from new ganglia module once it is finished.
        ganglia_hosts                           => ['10.4.0.79:8649'],
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


