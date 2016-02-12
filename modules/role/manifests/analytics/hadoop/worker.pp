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
