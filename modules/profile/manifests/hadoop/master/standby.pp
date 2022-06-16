# == Class profile::hadoop::master::standby
#
# Sets up a standby/backup Hadoop Master node.
#
#  [*monitoring_enabled*]
#    If production monitoring needs to be enabled or not.
#
class profile::hadoop::master::standby(
    $cluster_name             = lookup('profile::hadoop::common::hadoop_cluster_name'),
    $monitoring_enabled       = lookup('profile::hadoop::master::standby::monitoring_enabled', { 'default_value' => false }),
    $excluded_hosts           = lookup('profile::hadoop::master::standby::excluded_hosts', { 'default_value' => [] }),
) {
    require ::profile::hadoop::common

    if $monitoring_enabled {
        # Prometheus exporters
        require ::profile::hadoop::monitoring::namenode
        require ::profile::hadoop::monitoring::resourcemanager
    }

    class { '::bigtop::hadoop::namenode::standby':
        excluded_hosts => $excluded_hosts,
    }

    # Include icinga alerts if production realm.
    if $monitoring_enabled {
        # Icinga process alert for Stand By NameNode
        nrpe::monitor_service { 'hadoop-hdfs-namenode':
            description   => 'Hadoop Namenode - Stand By',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.server.namenode.NameNode"',
            contact_group => 'admins,analytics',
            require       => Class['bigtop::hadoop::namenode::standby'],
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Administration',
        }
        nrpe::monitor_service { 'hadoop-hdfs-zkfc':
            description   => 'Hadoop HDFS Zookeeper failover controller',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.tools.DFSZKFailoverController"',
            contact_group => 'admins,analytics',
            require       => Class['bigtop::hadoop::namenode::standby'],
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Administration',
        }
        # The standby nameserver writes copies of the FSTimage to disk every hour and
        # the backups are subsequently created from this image. This check warns if the
        # image is more than 90 minutes old and is critical of the image is more than 2 hours old
        # See T309649 for more information.
        nrpe::monitor_service { 'hadoop-hdfs-namenode-fsimage-age':
            description   => 'Hadoop HDFS Namenode FSImage Age',
            nrpe_command  => '/usr/lib/nagios/plugins/check_file_age -w 5400 -c 7200 -f /srv/hadoop/name/current/VERSION',
            contact_group => 'admins,analytics',
            require       => Class['bigtop::hadoop::namenode::standby'],
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Administration',
        }

        # Thresholds for the HDFS namenode are higher since it has always
        # filled most of its heap. This is not bad of course, but we'd like to know
        # if the usage stays above 90% over time to see if anything is happening.
        monitoring::check_prometheus { 'hadoop-hdfs-namenode-heap-usage':
            description     => 'HDFS active Namenode JVM Heap usage',
            dashboard_links => ["https://grafana.wikimedia.org/d/000000585/hadoop?orgId=1&viewPanel=4&var-hadoop_cluster=${cluster_name}"],
            query           => "scalar(avg_over_time(jvm_memory_bytes_used{hadoop_cluster=\"${cluster_name}\",instance=\"${::hostname}:10080\",area=\"heap\"}[60m])/avg_over_time(jvm_memory_bytes_max{hadoop_cluster=\"${cluster_name}\",instance=\"${::hostname}:10080\",area=\"heap\"}[60m]))",
            warning         => 0.9,
            critical        => 0.95,
            contact_group   => 'analytics',
            prometheus_url  => "http://prometheus.svc.${::site}.wmnet/analytics",
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Administration',
        }
    }

    class { '::bigtop::hadoop::resourcemanager': }

    # Include icinga alerts if production realm.
    if $monitoring_enabled {
        monitoring::check_prometheus { 'hadoop-yarn-resourcemananager-heap-usage':
            description     => 'YARN active ResourceManager JVM Heap usage',
            dashboard_links => ["https://grafana.wikimedia.org/d/000000585/hadoop?orgId=1&viewPanel=12&var-hadoop_cluster=${cluster_name}"],
            query           => "scalar(avg_over_time(jvm_memory_bytes_used{hadoop_cluster=\"${cluster_name}\",instance=\"${::hostname}:10083\",area=\"heap\"}[60m])/avg_over_time(jvm_memory_bytes_max{hadoop_cluster=\"${cluster_name}\",instance=\"${::hostname}:10083\",area=\"heap\"}[60m]))",
            warning         => 0.7,
            critical        => 0.9,
            contact_group   => 'analytics',
            prometheus_url  => "http://prometheus.svc.${::site}.wmnet/analytics",
            notes_link      => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Administration',
        }
    }
}
