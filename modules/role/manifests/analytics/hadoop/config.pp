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
    $gelf_logging_enabled                     = false

    # This needs to be set in order to use Impala
    $dfs_datanode_hdfs_blocks_metadata_enabled = true

    # Yarn App Master possible port ranges
    $yarn_app_mapreduce_am_job_client_port_range = '55000-55199'

    # Look up zookeeper_hosts from hiera.
    $zookeeper_hosts = keys(hiera('zookeeper_hosts', undef))

    # Configs specific to Production.
    if $::realm == 'production' {
        # This is the logical name of the Analytics Hadoop cluster.
        $cluster_name             = 'analytics-hadoop'

        $namenode_hosts           = [
            'analytics1001.eqiad.wmnet',
            'analytics1002.eqiad.wmnet',
        ]
        $resourcemanager_hosts = $namenode_hosts

        # JournalNodes are colocated on worker DataNodes.
        $journalnode_hosts        = [
            'analytics1052.eqiad.wmnet',  # Row A3
            'analytics1028.eqiad.wmnet',  # Row C2
            'analytics1035.eqiad.wmnet',  # Row D2
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

        $mapreduce_reduce_shuffle_parallelcopies  = 10
        $mapreduce_task_io_sort_mb                = 200
        $mapreduce_task_io_sort_factor            = 10


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

        ### The amount of RAM for NodeManagers will only be be used by NodeManager
        # processes running on the worker nodes themselves.  Client nodes that submit
        # jobs will ignore these settings.  These are safe to set relative to the
        # node currently evaluating puppet's facter variables.

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

        # use net-topology.py.erb to map hostname to /datacenter/rack/row id.
        $net_topology_script_template             = 'hadoop/net-topology.py.erb'
        $hadoop_heapsize                          = undef
        # Increase NameNode heapsize independent from other daemons
        $hadoop_namenode_opts                     = '-Xmx4096m'

        $yarn_heapsize                            = undef

        # TODO: use variables from new ganglia module once it is finished.
        $ganglia_host                             = '208.80.154.10'
        $ganglia_port                             = 9681
        $gelf_logging_host                        = 'logstash1002.eqiad.wmnet'
        $gelf_logging_port                        = 12201
        # In production, make sure that HDFS user directories are
        # created for everyone in these groups.
        $hadoop_users_posix_groups                = 'analytics-users analytics-privatedata-users analytics-admins analytics-search-users'
    }

    # Configs specific to Labs.
    elsif $::realm == 'labs' {
        # These variables are configurable via the
        # Labs Manage Instances GUI.
        $namenode_hosts = $::hadoop_namenodes ? {
            undef   => [$::fqdn],
            default => split($::hadoop_namenodes, ','),
        }
        $resourcemanager_hosts = $namenode_hosts

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
            "${hadoop_data_directory}/a",
            "${hadoop_data_directory}/b",
        ]

        # Labs sets these at undef, which lets the Hadoop defaults stick.
        $hadoop_namenode_opts                     = undef
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
        $yarn_scheduler_minimum_allocation_mb     = 0
        $yarn_scheduler_maximum_allocation_mb     = undef
        $yarn_scheduler_minimum_allocation_vcores = 0

        $net_topology_script_template             = undef

        $ganglia_host                             = 'aggregator.eqiad.wmflabs'
        $ganglia_port                             = 50090
        $gelf_logging_host                        = '127.0.0.1'
        $gelf_logging_port                        = 12201
        # In labs, make sure that HDFS user directories are
        # created for everyone in the current labs project.
        $hadoop_users_posix_groups                 = $::labsproject

        # Hadoop directories in labs should be automatically created.
        # This conditional could be added to each of the main classes
        # below, but since it doesn't hurt to have these directories
        # in labs, and since I don't want to add $::realm conditionals
        # below, I just create them here.
        file { [
            $hadoop_var_directory,
            $hadoop_data_directory,
        ]:
            ensure => 'directory',
        }
    }
}
