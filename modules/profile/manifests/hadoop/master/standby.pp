# == Class profile::hadoop::master::standby
#
# Sets up a standby/backup Hadoop Master node.
#
#  [*hadoop_namenode_heapsize*]
#    Current JVM heap size to use as threshold for monitoring.
#
#  [*monitoring_enabled*]
#    If production monitoring needs to be enabled or not.
#
class profile::hadoop::master::standby(
    $monitoring_enabled       = hiera('profile::hadoop::standby_master::monitoring_enabled', false),
    $hadoop_namenode_heapsize = hiera('profile::hadoop::standby::namenode_heapsize', 2048),
) {
    require ::profile::hadoop::common

    # Ensure that druid user exists on standby namenodes nodes.
    class { '::druid::cdh::hadoop::user':  }

    class { '::cdh::hadoop::namenode::standby': }

    # Include icinga alerts if production realm.
    if $monitoring_enabled {
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

        # Java heap space used alerts.
        # The goal is to get alarms for long running memory leaks like T153951.
        # Only include heap size alerts if heap size is configured.
        if $hadoop_namenode_heapsize {
            $nn_jvm_warning_threshold  = floor($hadoop_namenode_heapsize * 0.9 * 1000000)
            $nn_jvm_critical_threshold = floor($hadoop_namenode_heapsize * 0.95 * 1000000)
            monitoring::check_prometheus { 'hadoop-hdfs-namenode-heap-usage':
                description     => 'HDFS standby Namenode JVM Heap usage',
                dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/analytics-hadoop?orgId=1&panelId=4&fullscreen'],
                query           => "scalar(quantile_over_time(0.5,jvm_memory_bytes_used{instance=\"${::hostname}:10080\",area=\"heap\"}[120m]))",
                warning         => $nn_jvm_warning_threshold,
                critical        => $nn_jvm_critical_threshold,
                contact_group   => 'analytics',
                prometheus_url  => "http://prometheus.svc.${::site}.wmnet/analytics",
            }
        }
    }

    class { '::cdh::hadoop::resourcemanager': }

    # Include icinga alerts if production realm.
    if $monitoring_enabled {
        # Prometheus exporters
        include ::profile::hadoop::monitoring::namenode
        include ::profile::hadoop::monitoring::resourcemanager

        # The prometheus exporters can technically be deployed stand-alone
        # only requiring the hadoop commons configuration. The Hadoop daemons
        # though use the jmx exporter as -javaagent, so it needs to be deployed
        # before them to avoid any race conditions during the daemon first startup.
        Class['profile::hadoop::monitoring::resourcemanager'] -> Class['cdh::hadoop::resourcemanager']
        Class['profile::hadoop::monitoring::namenode'] -> Class['cdh::hadoop::namenode::standby']

        # Java heap space used alerts.
        # The goal is to get alarms for long running memory leaks like T153951.
        # Only include heap size alerts if heap size is configured.
        $hadoop_resourcemanager_heapsize = $::cdh::hadoop::yarn_heapsize
        if $hadoop_resourcemanager_heapsize {
            $rm_jvm_warning_threshold = floor($hadoop_resourcemanager_heapsize * 0.9 * 1000000)
            $rm_jvm_critical_threshold = floor($hadoop_resourcemanager_heapsize  * 0.95 * 1000000)
            monitoring::check_prometheus { 'hadoop-yarn-resourcemananager-heap-usage':
                description     => 'YARN standby Resource Manager JVM Heap usage',
                dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/analytics-hadoop?orgId=1&panelId=12&fullscreen'],
                query           => "scalar(quantile_over_time(0.5,jvm_memory_bytes_used{instance=\"${::hostname}:10083\",area=\"heap\"}[120m]))",
                warning         => $rm_jvm_warning_threshold,
                critical        => $rm_jvm_critical_threshold,
                contact_group   => 'analytics',
                prometheus_url  => "http://prometheus.svc.${::site}.wmnet/analytics",
            }
        }
    }
}
