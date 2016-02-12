# == Class role::analytics::hadoop
# Installs Hadoop client pacakges and configuration.
#
class role::analytics::hadoop::client inherits role::analytics::hadoop::config {
    # need java before hadoop is installed
    require_package('openjdk-7-jdk')

    class { 'cdh::hadoop':
        cluster_name                                => $cluster_name,
        namenode_hosts                              => $namenode_hosts,
        journalnode_hosts                           => $journalnode_hosts,
        resourcemanager_hosts                       => $resourcemanager_hosts,
        zookeeper_hosts                             => $zookeeper_hosts,
        datanode_mounts                             => $datanode_mounts,
        dfs_name_dir                                => [$hadoop_name_directory],
        dfs_journalnode_edits_dir                   => $hadoop_journal_directory,
        dfs_block_size                              => $dfs_block_size,
        io_file_buffer_size                         => $io_file_buffer_size,
        mapreduce_intermediate_compression_codec    => $mapreduce_intermediate_compression_codec,
        mapreduce_output_compression                => $mapreduce_output_compression,
        mapreduce_output_compression_codec          => $mapreduce_output_compression_codec,
        mapreduce_output_compression_type           => $mapreduce_output_compression_type,

        mapreduce_job_reuse_jvm_num_tasks           => $mapreduce_job_reuse_jvm_num_tasks,
        mapreduce_reduce_shuffle_parallelcopies     => $mapreduce_reduce_shuffle_parallelcopies,
        mapreduce_task_io_sort_mb                   => $mapreduce_task_io_sort_mb,
        mapreduce_task_io_sort_factor               => $mapreduce_task_io_sort_factor,

        mapreduce_map_memory_mb                     => $mapreduce_map_memory_mb,
        mapreduce_reduce_memory_mb                  => $mapreduce_reduce_memory_mb,
        mapreduce_map_java_opts                     => $mapreduce_map_java_opts,
        mapreduce_reduce_java_opts                  => $mapreduce_reduce_java_opts,
        yarn_app_mapreduce_am_resource_mb           => $yarn_app_mapreduce_am_resource_mb,
        yarn_app_mapreduce_am_command_opts          => $yarn_app_mapreduce_am_command_opts,
        yarn_app_mapreduce_am_job_client_port_range => $yarn_app_mapreduce_am_job_client_port_range,

        yarn_nodemanager_resource_memory_mb         => $yarn_nodemanager_resource_memory_mb,
        yarn_scheduler_minimum_allocation_mb        => $yarn_scheduler_minimum_allocation_mb,
        yarn_scheduler_maximum_allocation_mb        => $yarn_scheduler_maximum_allocation_mb,
        yarn_scheduler_minimum_allocation_vcores    => $yarn_scheduler_minimum_allocation_vcores,

        dfs_datanode_hdfs_blocks_metadata_enabled   => $dfs_datanode_hdfs_blocks_metadata_enabled,


        # Use net-topology.py.erb to map hostname to /datacenter/rack/row id.
        net_topology_script_template                => $net_topology_script_template,
        # Use fair-scheduler.xml.erb to define FairScheduler queues.
        fair_scheduler_template                     => $fair_scheduler_template,

        yarn_site_extra_properties                  => {
            # Enable FairScheduler preemption. This will allow the essential queue
            # to preempt non-essential jobs.
            'yarn.scheduler.fair.preemption'        => true,
            # Let YARN wait for at least 1/3 of nodes to present scheduling
            # opportunties before scheduling a job for certain data
            # on a node on which that data is not present.
            'yarn.scheduler.fair.locality.threshold.node' => '0.33',
            # After upgrading to CDH 5.4.0, we are encountering this bug:
            # https://issues.apache.org/jira/browse/MAPREDUCE-5799
            # This should work around the problem.
            'yarn.app.mapreduce.am.env'                   => 'LD_LIBRARY_PATH=/usr/lib/hadoop/lib/native',
            # The default of 90.0 for this was marking older dells as unhealthy when they still
            # had 2TB of space left.  99% will mark them at unhealthy with they still have
            # > 200G free.
            'yarn.nodemanager.disk-health-checker.max-disk-utilization-per-disk-percentage' => '99.0',
        },

        gelf_logging_enabled                        => $gelf_logging_enabled,
        gelf_logging_host                           => $gelf_logging_host,
        gelf_logging_port                           => $gelf_logging_port,

        hadoop_namenode_opts                        => $hadoop_namenode_opts,
    }

    # If in production AND the current node is a journalnode, then
    # go ahead and include an icinga alert for the JournalNode process.
    if $::realm == 'production' and member($journalnode_hosts, $::fqdn) {
        nrpe::monitor_service { 'hadoop-hdfs-journalnode':
            description  => 'Hadoop JournalNode',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.qjournal.server.JournalNode"',
            require      => Class['cdh::hadoop'],
            critical     => true,
        }
    }
    file { '/usr/local/bin/hadoop-yarn-logging-helper.sh':
        content => template('hadoop/hadoop-yarn-logging-helper.erb'),
        mode    => '0744',
    }
    if $gelf_logging_enabled {
        ensure_packages([
            # library dependency
            'libjson-simple-java',
            # the libary itself: logstash-gelf.jar
            'liblogstash-gelf-java',
        ])
        # symlink into hadoop classpath
        file { '/usr/lib/hadoop/lib/json_simple.jar':
            ensure  => 'link',
            target  => '/usr/share/java/json_simple.jar',
            require => Package['libjson-simple-java'],
        }

        # symlink into hadoop classpath
        file { '/usr/lib/hadoop/lib/logstash-gelf.jar':
            ensure  => 'link',
            target  => '/usr/share/java/logstash-gelf.jar',
            require => Package['liblogstash-gelf-java'],
        }
        # Patch container-log4j.properties inside nodemanager jar
        # See script source for details
        exec { 'hadoop-yarn-logging-helper-set':
            command   => '/usr/local/bin/hadoop-yarn-logging-helper.sh set',
            subscribe => File['/usr/local/bin/hadoop-yarn-logging-helper.sh'],
        }
    } else {
        # Revert to original unmodified jar
        exec { 'hadoop-yarn-logging-helper-reset':
            command   => '/usr/local/bin/hadoop-yarn-logging-helper.sh reset',
            subscribe => File['/usr/local/bin/hadoop-yarn-logging-helper.sh'],
        }
    }

    # Temporarily hardode DNS CNAMES into /etc/hosts.
    # jobs are failing around the cluster because these
    # are cached in DNS.  I need to fix now.  Will remove
    # this after new DNS has propogated.
    file_line { 'hadoop_master_cname_dns_override':
      ensure => 'absent',
      path   => '/etc/hosts',
      line   => '10.64.36.118    namenode.analytics.eqiad.wmnet resoucemanager.analytics.eqiad.wmnet',
    }

    # Install packages that are useful for distributed
    # computation in Hadoop, and thus should be available on
    # any Hadoop nodes.
    ensure_packages([
        # Need python3 on Hadoop nodes in order to run
        # Hadoop Streaming python jobs.
        'python3',
        'python-numpy',
        'python-pandas',
        'python-scipy',
        'python-requests',
        'python-matplotlib',
        'python-dateutil',
        'python-sympy',
    ])
}
