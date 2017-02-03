# == Class role::analytics_cluster::hadoop::standby
# Include standby NameNode classes
#
class role::analytics_cluster::hadoop::standby {
    system::role { 'analytics_cluster::hadoop::standby':
        description => 'Hadoop Standby NameNode',
    }
    require ::role::analytics_cluster::hadoop::client
    include ::role::analytics_cluster::monitoring::disks

    class { '::cdh::hadoop::namenode::standby': }

    # Use jmxtrans for sending metrics
    class { '::cdh::hadoop::jmxtrans::namenode':
        statsd  => hiera('statsd'),
    }

    # Include icinga alerts if production realm.
    if $::realm == 'production' {
        # Icinga process alert for Stand By NameNode
        nrpe::monitor_service { 'hadoop-hdfs-namenode':
            description   => 'Hadoop Namenode - Stand By',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.server.namenode.NameNode"',
            contact_group => 'admins,analytics',
            require       => Class['cdh::hadoop::namenode::standby'],
            critical      => true,
        }
        nrpe::monitor_service { 'hadoop-hdfs-zkfc':
            description   => 'Hadoop HDFS Zookeeper failover controller',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.tools.DFSZKFailoverController"',
            contact_group => 'admins,analytics',
            require       => Class['cdh::hadoop::namenode::standby'],
        }

        # Java heap space used alerts
        # The goal is to get alarms for long running memory leaks like T153951
        $namenode_jvm_warning_threshold  = hiera(cdh::hadoop::hadoop_namenode_heapsize) * 0.7
        $namenode_jvm_critical_threshold = hiera(cdh::hadoop::hadoop_namenode_heapsize) * 0.9
        monitoring::graphite_threshold { 'analytics_hadoop_namenode_hdfs':
            description   => 'HDFS standby Namenode JVM Heap usage',
            metric        => "Hadoop.NameNode.${::hostname}_eqiad_wmnet_9980.Hadoop.NameNode.JvmMetrics.MemHeapUsedM.upper",
            from          => '60min',
            warning       => $namenode_jvm_warning_threshold,
            critical      => $namenode_jvm_critical_threshold,
            percentage    => '60',
            contact_group => 'admins,analytics',
        }
    }

    # Firewall
    include ::role::analytics_cluster::hadoop::ferm::namenode

    # If this is a resourcemanager host, then go ahead
    # and include a resourcemanager on all standby nodes as well
    # as the master node.
    if $::fqdn in $::cdh::hadoop::resourcemanager_hosts {
        include ::cdh::hadoop::resourcemanager
        # Firewall
        include ::role::analytics_cluster::hadoop::ferm::resourcemanager

        # Use jmxtrans for sending metrics
        class { 'cdh::hadoop::jmxtrans::resourcemanager':
            statsd  => hiera('statsd'),
        }

        # Java heap space used alerts
        # The goal is to get alarms for long running memory leaks like T153951
        $rm_jvm_warning_threshold  = hiera(cdh::hadoop::yarn_heapsize) * 0.7
        $rm_jvm_critical_threshold = hiera(cdh::hadoop::yarn_heapsize) * 0.9
        monitoring::graphite_threshold { 'analytics_hadoop_yarn_resource_manager':
            description   => 'YARN Resource Manager JVM Heap usage',
            metric        => "Hadoop.ResourceManager.${::hostname}_eqiad_wmnet_9984.Hadoop.ResourceManager.JvmMetrics.MemHeapUsedM.upper",
            from          => '60min',
            warning       => $rm_jvm_warning_threshold,
            critical      => $rm_jvm_critical_threshold,
            percentage    => '60',
            contact_group => 'admins,analytics',
        }
    }

}
