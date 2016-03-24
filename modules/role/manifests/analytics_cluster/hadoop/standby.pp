# == Class role::analytics_cluster::hadoop::standby
# Include standby NameNode classes
#
class role::analytics_cluster::hadoop::standby {
    system::role { 'analytics_cluster::hadoop::standby':
        description => 'Hadoop Standby NameNode',
    }
    require role::analytics_cluster::hadoop::client
    include role::analytics_cluster::monitoring::disks

    class { 'cdh::hadoop::namenode::standby': }

    # Use jmxtrans for sending metrics
    class { 'cdh::hadoop::jmxtrans::namenode':
        statsd  => hiera('statsd'),
    }

    # Include icinga alerts if production realm.
    if $::realm == 'production' {
        # Icinga process alert for Stand By NameNode
        nrpe::monitor_service { 'hadoop-hdfs-namenode':
            description  => 'Hadoop Namenode - Stand By',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.server.namenode.NameNode"',
            require      => Class['cdh::hadoop::namenode::standby'],
            critical     => true,
        }
        nrpe::monitor_service { 'hadoop-hdfs-zkfc':
            description  => 'Hadoop HDFS Zookeeper failover controller',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.tools.DFSZKFailoverController"',
            require      => Class['cdh::hadoop::namenode::standby'],
        }
    }

    # Firewall
    include role::analytics_cluster::hadoop::ferm::namenode

    # If this is a resourcemanager host, then go ahead
    # and include a resourcemanager on all standby nodes as well
    # as the master node.
    if $::fqdn in $::cdh::hadoop::resourcemanager_hosts {
        include cdh::hadoop::resourcemanager
        # Firewall
        include role::analytics_cluster::hadoop::ferm::resourcemanager
    }

}