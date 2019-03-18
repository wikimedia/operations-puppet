# == Class profile::hadoop::master::standby
#
# Sets up a standby/backup Hadoop Master node.
#
#  [*monitoring_enabled*]
#    If production monitoring needs to be enabled or not.
#
class profile::hadoop::master::standby(
    $cluster_name             = hiera('profile::hadoop::common::hadoop_cluster_name'),
    $monitoring_enabled       = hiera('profile::hadoop::standby_master::monitoring_enabled', false),
    $use_kerberos             = hiera('profile::hadoop::standby_master::use_kerberos', false),
    $excluded_hosts           = hiera('profile::hadoop::standby_master::excluded_hosts', []),
) {
    require ::profile::hadoop::common

    # Ensure that druid user exists on standby namenodes nodes.
    class { '::druid::cdh::hadoop::user':
        use_kerberos => $use_kerberos,
    }

    if $monitoring_enabled {
        # Prometheus exporters
        require ::profile::hadoop::monitoring::namenode
        require ::profile::hadoop::monitoring::resourcemanager
    }

    class { '::cdh::hadoop::namenode::standby':
        use_kerberos   => $use_kerberos,
        excluded_hosts => $excluded_hosts,
    }

    # Include icinga alerts if production realm.
    if $monitoring_enabled {
        # Icinga process alert for Stand By NameNode
        nrpe::monitor_service { 'hadoop-hdfs-namenode':
            description   => 'Hadoop Namenode - Stand By',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.server.namenode.NameNode"',
            contact_group => 'admins,analytics',
            require       => Class['cdh::hadoop::namenode::standby'],
            critical      => true,
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Administration',
        }
        nrpe::monitor_service { 'hadoop-hdfs-zkfc':
            description   => 'Hadoop HDFS Zookeeper failover controller',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.tools.DFSZKFailoverController"',
            contact_group => 'admins,analytics',
            require       => Class['cdh::hadoop::namenode::standby'],
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Administration',
        }

        # Thresholds for the HDFS namenode are higher since it has always
        # filled most of its heap. This is not bad of course, but we'd like to know
        # if the usage stays above 90% over time to see if anything is happening.
        monitoring::check_prometheus { 'hadoop-hdfs-namenode-heap-usage':
            description     => 'HDFS active Namenode JVM Heap usage',
            dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/hadoop?var-hadoop_cluster=${cluster_name}&panelId=4&fullscreen&orgId=1"],
            query           => "scalar(avg_over_time(jvm_memory_bytes_used{hadoop_cluster=\"${cluster_name}\",instance=\"${::hostname}:10080\",area=\"heap\"}[60m])/avg_over_time(jvm_memory_bytes_max{hadoop_cluster=\"${cluster_name}\",instance=\"${::hostname}:10080\",area=\"heap\"}[60m]))",
            warning         => 0.9,
            critical        => 0.95,
            contact_group   => 'analytics',
            prometheus_url  => "http://prometheus.svc.${::site}.wmnet/analytics",
        }
    }

    class { '::cdh::hadoop::resourcemanager':
        use_kerberos => $use_kerberos,
    }

    # Include icinga alerts if production realm.
    if $monitoring_enabled {
        monitoring::check_prometheus { 'hadoop-yarn-resourcemananager-heap-usage':
            description     => 'YARN active ResourceManager JVM Heap usage',
            dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/hadoop?var-hadoop_cluster=${cluster_name}&panelId=12&fullscreen&orgId=1"],
            query           => "scalar(avg_over_time(jvm_memory_bytes_used{hadoop_cluster=\"${cluster_name}\",instance=\"${::hostname}:10083\",area=\"heap\"}[60m])/avg_over_time(jvm_memory_bytes_max{hadoop_cluster=\"${cluster_name}\",instance=\"${::hostname}:10083\",area=\"heap\"}[60m]))",
            warning         => 0.7,
            critical        => 0.9,
            contact_group   => 'analytics',
            prometheus_url  => "http://prometheus.svc.${::site}.wmnet/analytics",
        }
    }
}
