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
#                       This list will also be used as $resourcemanager_hosts.
#                       If hiera('zookeeper_hosts') is set, and this list has more
#                       than one entry, and $journalnode_hosts is also set, then
#                       HA YARN ResourceManager will be configured.
#                       TODO: Change the name of this variable to hadoop_masters
#                       When we make this work better with hiera.
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

# == Class role::analytics::hadoop::ferm::namenode
#
class role::analytics::hadoop::ferm::namenode {
    ferm::service{ 'hadoop-hdfs-namenode':
        proto  => 'tcp',
        port   => '8020',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'hadoop-hdfs-namenode-http-ui':
        proto  => 'tcp',
        port   => '50070',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'hadoop-hdfs-httpfs':
        proto  => 'tcp',
        port   => '14000',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'hadoop-hdfs-namenode-jmx':
        proto  => 'tcp',
        port   => '9980',
        srange => '$ANALYTICS_NETWORKS',
    }
}

# == Class role::analytics::hadoop::ferm::resourcemanager
#

class role::analytics::hadoop::ferm::resourcemanager {

    ferm::service{ 'hadoop-yarn-resourcemanager-scheduler':
        proto  => 'tcp',
        port   => '8030',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'hadoop-yarn-resourcemanager-tracker':
        proto  => 'tcp',
        port   => '8031',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'hadoop-yarn-resourcemanager':
        proto  => 'tcp',
        port   => '8032',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'hadoop-yarn-resourcemanager-admin':
        proto  => 'tcp',
        port   => '8033',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'hadoop-yarn-resourcemanager-http-ui':
        proto  => 'tcp',
        port   => '8088',
        srange => '$INTERNAL',
    }

    ferm::service{ 'hadoop-mapreduce-historyserver':
        proto  => 'tcp',
        port   => '10020',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'hadoop-mapreduce-historyserver-admin':
        proto  => 'tcp',
        port   => '10033',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'hadoop-mapreduce-historyserver-http-ui':
        proto  => 'tcp',
        port   => '19888',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'hadoop-yarn-resourcemanager-jmx':
        proto  => 'tcp',
        port   => '9983',
        srange => '$ANALYTICS_NETWORKS',
    }


}


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
    # Use jmxtrans for sending metrics to ganglia and statsd

    # TODO: use variables for stats server from somewhere?
    $statsd  = 'statsd.eqiad.wmnet:8125'

    class { 'cdh::hadoop::jmxtrans::master':
        ganglia => "${ganglia_host}:${ganglia_port}",
        statsd  => $statsd,
    }

    # monitor disk statistics
    include role::analytics::monitor_disks

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
            critical     => true,
        }
        nrpe::monitor_service { 'hadoop-yarn-resourcemanager':
            description  => 'Hadoop ResourceManager',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.yarn.server.resourcemanager.ResourceManager"',
            require      => Class['cdh::hadoop::master'],
            critical     => true,
        }
        nrpe::monitor_service { 'hadoop-mapreduce-historyserver':
            description  => 'Hadoop HistoryServer',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.mapreduce.v2.hs.JobHistoryServer"',
            require      => Class['cdh::hadoop::master'],
        }

        # Allow nagios to run the check_hdfs_active_namenode as hdfs user.
        sudo::user { 'nagios-check_hdfs_active_namenode':
            user       => 'nagios',
            privileges => ['ALL = NOPASSWD: /usr/local/bin/check_hdfs_active_namenode'],
        }
        # Alert if there is no active NameNode
        nrpe::monitor_service { 'hadoop-hdfs-active-namenode':
            description  => 'At least one Hadoop HDFS NameNode is active',
            nrpe_command => '/usr/bin/sudo /usr/local/bin/check_hdfs_active_namenode',
            require      => [
                Class['cdh::hadoop::master'],
                Sudo::User['nagios-check_hdfs_active_namenode'],
            ],
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


    # Firewall
    include role::analytics::hadoop::ferm::namenode
    include role::analytics::hadoop::ferm::resourcemanager
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
        statsd  => $statsd,
    }

    # monitor disk statistics
    include role::analytics::monitor_disks

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

        # Alert on datanode mount disk space.  These mounts are ignored by the
        # base module's check_disk via the base::monitoring::host::nrpe_check_disk_options
        # override in worker.yaml hieradata.
        nrpe::monitor_service { 'disk_space_hadoop_worker':
            description  => 'Disk space on Hadoop worker',
            nrpe_command => '/usr/lib/nagios/plugins/check_disk --units GB -w 32 -c 16 -e -l  -r "/var/lib/hadoop/data"',
        }

        # Make sure that this worker node has NodeManager running in a RUNNING state.
        # Install a custom check command for NodeManager Node-State:
        file { '/usr/local/lib/nagios/plugins/check_hadoop_yarn_node_state':
            source => 'puppet:///files/hadoop/check_hadoop_yarn_node_state',
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
        nrpe::monitor_service { 'hadoop_yarn_node_state':
            description  => 'YARN NodeManager Node-State',
            nrpe_command => '/usr/local/lib/nagios/plugins/check_hadoop_yarn_node_state',
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

    # Install MaxMind databases for geocoding UDFs
    include geoip


    # Firewall
    ferm::service{ 'hadoop-access':
        proto  => 'tcp',
        port   => '1024:65535',
        srange => '$ANALYTICS_NETWORKS',
    }
}

# == Class role::analytics::hadoop::monitor::nsca::client
# This class exists in order to override the group ownership
# and permissions of the /etc/send_nsca.cfg file.  Hadoop
# processes need to be able to read this file in order to
# run send_nsca as part of Oozie submitted monitoring jobs.
class role::analytics::hadoop::monitor::nsca::client inherits icinga::nsca::client {
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
    include role::analytics::monitor_disks


    # Include icinga alerts if production realm.
    if $::realm == 'production' {
        # Icinga process alert for Stand By NameNode
        nrpe::monitor_service { 'hadoop-hdfs-namenode':
            description  => 'Hadoop Namenode - Stand By',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.server.namenode.NameNode"',
            require      => Class['cdh::hadoop::namenode::standby'],
            critical     => true,
        }
    }

    # If this is a resourcemanager host, then go ahead
    # and include a resourcemanager on all standby nodes as well
    # as the master node.
    if $::fqdn in $resourcemanager_hosts {
        include cdh::hadoop::resourcemanager
        # Firewall
        include role::analytics::hadoop::ferm::resourcemanager
    }


    # Firewall
    include role::analytics::hadoop::ferm::namenode
}


# == Class role::analytics::hadoop::balancer
# Runs hdfs balancer periodically to keep data balanced across all DataNodes
class role::analytics::hadoop::balancer {
    Class['role::analytics::hadoop::client'] -> Class['role::analytics::hadoop::balancer']

    file { '/usr/local/bin/hdfs-balancer':
        source => 'puppet:///files/hadoop/hdfs-balancer',
        mode   => '0754',
        owner  => 'hdfs',
        group  => 'hdfs',
    }

    cron { 'hdfs-balancer':
        command => '/usr/local/bin/hdfs-balancer >> /var/log/hadoop-hdfs/balancer.log 2>&1',
        user    => 'hdfs',
        # Every day at 6am UTC.
        minute  => 0,
        hour    => 6,
        require => File['/usr/local/bin/hdfs-balancer'],
    }
}
