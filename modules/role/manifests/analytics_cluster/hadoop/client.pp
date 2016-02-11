# == Class role::analytics::hadoop::client
# Installs Hadoop client pacakges and configuration.
#
class role::analytics_cluster::hadoop::client {
    # Need Java before Hadoop is installed.
    require role::analytics_cluster::java

    $hadoop_var_directory                     = '/var/lib/hadoop'
    $hadoop_name_directory                    = "${hadoop_var_directory}/name"
    $hadoop_data_directory                    = "${hadoop_var_directory}/data"
    $hadoop_journal_directory                 = "${hadoop_var_directory}/journal"

    # [WIP] Use hiera to configure Hadoop in labs.
    # You MUST set at least the following:
    #  cdh::hadoop::cluster_name
    #  cdh::hadoop::namenode_hosts
    #
    class { 'cdh::hadoop':
        # Default to using running resourcemanager on the same hosts
        # as the namenodes.
        resourcemanager_hosts                       => hiera(
            'cdh::hadoop::resourcemanager_hosts', hiera('cdh::hadoop::namenode_hosts')
        ),
        zookeeper_hosts                             => keys(hiera('zookeeper_hosts', undef)),
        dfs_name_dir                                => [$hadoop_name_directory],
        dfs_journalnode_edits_dir                   => $hadoop_journal_directory,

        # 256 MB
        dfs_block_size                              => 268435456,
        io_file_buffer_size                         => 131072,

        # Turn on Snappy compression by default for maps and final outputs
        mapreduce_intermediate_compression_codec    => 'org.apache.hadoop.io.compress.SnappyCodec',
        mapreduce_output_compression                => true,
        mapreduce_output_compression_codec          => 'org.apache.hadoop.io.compress.SnappyCodec',
        mapreduce_output_compression_type           => 'BLOCK',

        mapreduce_job_reuse_jvm_num_tasks           => 1,

        # This needs to be set in order to use Impala
        dfs_datanode_hdfs_blocks_metadata_enabled   => true,

        # Use fair-scheduler.xml.erb to define FairScheduler queues.
        fair_scheduler_template                     => 'role/analytics_cluster/hadoop/fair-scheduler.xml.erb',

        # Yarn App Master possible port ranges
        yarn_app_mapreduce_am_job_client_port_range => '55000-55199',

        yarn_site_extra_properties                  => {
            # Enable FairScheduler preemption. This will allow the essential queue
            # to preempt non-essential jobs.
            'yarn.scheduler.fair.preemption'              => true,
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
    }

    # If in production AND the current node is a journalnode, then
    # go ahead and include an icinga alert for the JournalNode process.
    if $::realm == 'production' and member($cdh::hadoop::journalnode_hosts, $::fqdn) {
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
    if $::cdh::hadoop::gelf_logging_enabled {
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

    # NOTE: Hadoop Memory Settings are configured here instead of
    # hiera. Many of these settings are configured programatically and
    # based on dynamic facter variables.
    if $::realm == 'production' {
        # Configure memory based on these recommendations and then adjusted:
        # http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.6.0/bk_installing_manually_book/content/rpm-chap1-11.html

        ### These Map/Reduce and YARN ApplicationMaster master settings are
        # settable per job, and the defaults when clients submit them are often
        # picked up from the local versions of the /etc/hadoop/conf/{mapred,yarn}-site.xml files.
        # That means they should not be set relative to the local node facter variables, and as such
        # use a hardcoded value of memory_per_container to work from.  Otherwise a job
        # submitted from a relatively small client node will use bad job defaults.
        #
        # We currently run two different types of worker nodes in production.
        # The older Dells have 48G of RAM, and the newer ones have 64G.
        #
        # Using + 0 here ensures that these variables are
        # integers (Fixnums) and won't throw errors
        # when used with min()/max() functions.

        # Worker nodes are heterogenous, so I don't want to use a variable
        # memory per container size across the cluster.  Larger nodes will just
        # allocate a few more containers.  Setting this to 2G.
        $memory_per_container_mb                  = 2048 + 0

        # Map container size and JVM max heap size (-XmX)
        $mapreduce_map_memory_mb                  = floor($memory_per_container_mb)
        $mapreduce_reduce_memory_mb               = floor(2 * $memory_per_container_mb)
        $map_jvm_heap_size                        = floor(0.8 * $memory_per_container_mb)
        # Reduce container size and JVM max heap size (-Xmx)
        $mapreduce_map_java_opts                  = "-Xmx${map_jvm_heap_size}m"
        $reduce_jvm_heap_size                     = floor(0.8 * 2 * $memory_per_container_mb)
        $mapreduce_reduce_java_opts               = "-Xmx${reduce_jvm_heap_size}m"

        # Yarn ApplicationMaster container size and  max heap size (-Xmx)
        $yarn_app_mapreduce_am_resource_mb        = floor(2 * $memory_per_container_mb)
        $mapreduce_am_heap_size                   = floor(0.8 * 2 * $memory_per_container_mb)
        $yarn_app_mapreduce_am_command_opts       = "-Xmx${mapreduce_am_heap_size}m"

        # The amount of RAM for NodeManagers will only be be used by
        # NodeManager processes running on the worker nodes themselves.
        # Client nodes that submit jobs will ignore these settings.
        # These are safe to set relative to the node currently evaluating
        # puppet's facter variables.

        # Select a 'reserve' memory size for the
        # OS and other Hadoop processes.
        if $::memorysize_mb <= 1024 {
            $reserve_memory_mb = 256
        }
        elsif $::memorysize_mb <= 2048 {
            $reserve_memory_mb = 512
        }
        elsif $::memorysize_mb <= 4096 {
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

        # Since I have chosen a static $memory_per_container of 2048 across all
        # node sizes, we should just choose to give NodeManagers
        # $available_memory_mb to work with.
        # This will give nodes with 48G of memory about 21 containers, and
        # nodes with 64G memory about 28 containers.
        #
        # This is the total amount of memory that NodeManagers
        # will use for allocation to containers.
        $yarn_nodemanager_resource_memory_mb      = floor($available_memory_mb)

        # Setting _minimum_allocation_mb to 0 to allow Impala to submit small reservation requests.
        $yarn_scheduler_minimum_allocation_mb     = 0
        $yarn_scheduler_maximum_allocation_mb     = $yarn_nodemanager_resource_memory_mb
        # Setting minimum_allocation_vcores to 0 to allow Impala to submit small reservation requests.
        $yarn_scheduler_minimum_allocation_vcores = 0

        Class['cdh::hadoop'] {
            mapreduce_map_memory_mb                     => $mapreduce_map_memory_mb,
            mapreduce_reduce_memory_mb                  => $mapreduce_reduce_memory_mb,
            mapreduce_map_java_opts                     => $mapreduce_map_java_opts,
            mapreduce_reduce_java_opts                  => $mapreduce_reduce_java_opts,
            yarn_app_mapreduce_am_resource_mb           => $yarn_app_mapreduce_am_resource_mb,
            yarn_app_mapreduce_am_command_opts          => $yarn_app_mapreduce_am_command_opts,

            yarn_nodemanager_resource_memory_mb         => $yarn_nodemanager_resource_memory_mb,
            yarn_scheduler_minimum_allocation_mb        => $yarn_scheduler_minimum_allocation_mb,
            yarn_scheduler_maximum_allocation_mb        => $yarn_scheduler_maximum_allocation_mb,
            yarn_scheduler_minimum_allocation_vcores    => $yarn_scheduler_minimum_allocation_vcores,
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
        }
    }
}
