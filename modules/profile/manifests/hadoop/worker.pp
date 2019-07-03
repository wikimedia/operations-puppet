# == Class profile::hadoop::worker
#
# Configure a Analytics Hadoop worker node.
#
# == Parameters
#
#  [*monitoring_enabled*]
#    If production monitoring needs to be enabled or not.
#
#  [*use_kerberos*]
#    Make Puppet use Kerberos authentication when executing hdfs commands.
#
class profile::hadoop::worker(
    $cluster_name       = hiera('profile::hadoop::common::hadoop_cluster_name'),
    $monitoring_enabled = hiera('profile::hadoop::worker::monitoring_enabled', false),
    $ferm_srange        = hiera('profile::hadoop::worker::ferm_srange', '$DOMAIN_NETWORKS'),
    $use_kerberos       = hiera('profile::hadoop::worker::use_kerberos', false),
) {
    require ::profile::analytics::cluster::packages::common
    require ::profile::hadoop::common

    # hive::client is nice to have for jobs launched
    # from random worker nodes as app masters so they
    # have access to hive-site.xml and other hive jars.
    # This installs hive-hcatalog package on worker nodes to get
    # hcatalog jars, including Hive JsonSerde for using
    # JSON backed Hive tables.
    include ::profile::hive::client

    # Spark 2 is manually packaged by us, it is not part of CDH.
    include ::profile::hadoop::spark2

    if $monitoring_enabled {
        # Prometheus exporters
        require ::profile::hadoop::monitoring::datanode
        require ::profile::hadoop::monitoring::nodemanager
    }

    class { '::cdh::hadoop::worker': }

    # The HDFS journalnodes are co-located for convenience,
    # but it is not a strict requirement.
    if $::fqdn in $::cdh::hadoop::journalnode_hosts {
        if $monitoring_enabled {
            require profile::hadoop::monitoring::journalnode
        }
        class { 'cdh::hadoop::journalnode': }
    }

    # sqoop needs to be on worker nodes if Oozie is to
    # launch sqoop jobs.
    class { '::cdh::sqoop': }


    # This allows Hadoop daemons to talk to each other.
    ferm::service{ 'hadoop-access':
        proto  => 'tcp',
        port   => '1024:65535',
        srange => $ferm_srange,
    }

    if $monitoring_enabled {
        # Icinga process alerts for DataNode and NodeManager
        nrpe::monitor_service { 'hadoop-hdfs-datanode':
            description   => 'Hadoop DataNode',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.server.datanode.DataNode"',
            contact_group => 'admins,analytics',
            require       => Class['cdh::hadoop::worker'],
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Administration',
        }
        nrpe::monitor_service { 'hadoop-yarn-nodemanager':
            description   => 'Hadoop NodeManager',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.yarn.server.nodemanager.NodeManager"',
            contact_group => 'admins,analytics',
            require       => Class['cdh::hadoop::worker'],
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Administration',
        }

        if $::fqdn in $::cdh::hadoop::journalnode_hosts {
            nrpe::monitor_service { 'hadoop-hdfs-journalnode':
                description   => 'Hadoop JournalNode',
                nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.qjournal.server.JournalNode"',
                contact_group => 'admins,analytics',
                require       => Class['cdh::hadoop'],
                notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Administration',
            }
        }

        # Alert on datanode mount disk space.  These mounts are ignored by the
        # base module's check_disk via the base::monitoring::host::nrpe_check_disk_options
        # override in worker.yaml hieradata.
        nrpe::monitor_service { 'disk_space_hadoop_worker':
            description   => 'Disk space on Hadoop worker',
            nrpe_command  => '/usr/lib/nagios/plugins/check_disk --units GB -w 32 -c 16 -e -l  -r "/var/lib/hadoop/data"',
            contact_group => 'admins,analytics',
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Administration',
        }

        monitoring::check_prometheus { 'analytics_hadoop_hdfs_datanode':
            description     => 'HDFS DataNode JVM Heap usage',
            dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/hadoop?var-hadoop_cluster=${cluster_name}&panelId=1&fullscreen&orgId=1"],
            query           => "scalar(avg_over_time(jvm_memory_bytes_used{hadoop_cluster=\"${cluster_name}\",instance=\"${::hostname}:51010\",area=\"heap\"}[60m])/avg_over_time(jvm_memory_bytes_max{hadoop_cluster=\"${cluster_name}\",instance=\"${::hostname}:51010\",area=\"heap\"}[60m]))",
            warning         => 0.9,
            critical        => 0.95,
            contact_group   => 'analytics',
            prometheus_url  => "http://prometheus.svc.${::site}.wmnet/analytics",
        }

        monitoring::check_prometheus { 'analytics_hadoop_yarn_nodemanager':
            description     => 'YARN NodeManager JVM Heap usage',
            dashboard_links => ["https://grafana.wikimedia.org/dashboard/db/hadoop?var-hadoop_cluster=${cluster_name}&orgId=1&panelId=17&fullscreen"],
            query           => "scalar(avg_over_time(jvm_memory_bytes_used{hadoop_cluster=\"${cluster_name}\",instance=\"${::hostname}:8141\",area=\"heap\"}[60m])/avg_over_time(jvm_memory_bytes_max{hadoop_cluster=\"${cluster_name}\",instance=\"${::hostname}:8141\",area=\"heap\"}[60m]))",
            warning         => 0.9,
            critical        => 0.95,
            contact_group   => 'analytics',
            prometheus_url  => "http://prometheus.svc.${::site}.wmnet/analytics",
        }
    }
}
