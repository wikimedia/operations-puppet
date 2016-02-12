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
