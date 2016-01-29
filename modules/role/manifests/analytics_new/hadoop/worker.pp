# == Class role::analytics::hadoop::worker
# Includes cdh::hadoop::worker classes
class role::analytics_new::hadoop::worker {
    system::role { 'role::analytics::hadoop::worker':
        description => 'Hadoop Worker (DataNode & NodeManager)',
    }

    require role::analytics_new::hadoop::client
    include role::analytics_new::monitoring::disks

    class { 'cdh::hadoop::worker': }

    # Use jmxtrans for sending metrics
    class { 'cdh::hadoop::jmxtrans::worker':
        statsd  => hiera('statsd'),
    }

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
            source => 'puppet:///modules/role/analytics_new/hadoop/check_hadoop_yarn_node_state',
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
    include role::analytics_new::hive::client

    # Install MaxMind databases for geocoding UDFs
    include geoip

    # Install packages that are useful for distributed
    # computation in Hadoop, and thus should be available on
    # any Hadoop nodes.
    require_package(
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
    )

    # This allows Hadoop daemons to talk to each other.
    ferm::service{ 'hadoop-access':
        proto  => 'tcp',
        port   => '1024:65535',
        srange => '$ANALYTICS_NETWORKS',
    }
}