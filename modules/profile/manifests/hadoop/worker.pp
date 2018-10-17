# == Class profile::hadoop::worker
#
# Configure a Analytics Hadoop worker node.
#
# == Parameters
#
#  [*monitoring_enabled*]
#    If production monitoring needs to be enabled or not.
#
class profile::hadoop::worker(
    $cluster_name       = hiera('profile::hadoop::common::hadoop_cluster_name'),
    $monitoring_enabled = hiera('profile::hadoop::worker::monitoring_enabled', false),
    $ferm_srange        = hiera('profile::hadoop::worker::ferm_srange', '$DOMAIN_NETWORKS'),
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

    class { '::cdh::hadoop::worker': }

    # The HDFS journalnodes are co-located for convenience,
    # but it is not a strict requirement.
    if $::fqdn in $::cdh::hadoop::journalnode_hosts {
        if $monitoring_enabled {
            require profile::hadoop::monitoring::journalnode
        }
        class { 'cdh::hadoop::journalnode': }
    }

    # Spark Python stopped working in Spark 1.5.0 with Oozie,
    # for complicated reasons.  We need to be able to set
    # SPARK_HOME in an oozie launcher, and that SPARK_HOME
    # needs to point at a locally installed spark directory
    # in order load Spark Python dependencies.
    class { '::cdh::spark': }

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
        # Prometheus exporters
        require ::profile::hadoop::monitoring::datanode
        require ::profile::hadoop::monitoring::nodemanager

        # Icinga process alerts for DataNode and NodeManager
        nrpe::monitor_service { 'hadoop-hdfs-datanode':
            description   => 'Hadoop DataNode',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.server.datanode.DataNode"',
            contact_group => 'admins,analytics',
            require       => Class['cdh::hadoop::worker'],
        }
        nrpe::monitor_service { 'hadoop-yarn-nodemanager':
            description   => 'Hadoop NodeManager',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.yarn.server.nodemanager.NodeManager"',
            contact_group => 'admins,analytics',
            require       => Class['cdh::hadoop::worker'],
        }

        if $::fqdn in $::cdh::hadoop::journalnode_hosts {
            nrpe::monitor_service { 'hadoop-hdfs-journalnode':
                description   => 'Hadoop JournalNode',
                nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.qjournal.server.JournalNode"',
                contact_group => 'admins,analytics',
                require       => Class['cdh::hadoop'],
            }
        }

        # Alert on datanode mount disk space.  These mounts are ignored by the
        # base module's check_disk via the base::monitoring::host::nrpe_check_disk_options
        # override in worker.yaml hieradata.
        nrpe::monitor_service { 'disk_space_hadoop_worker':
            description   => 'Disk space on Hadoop worker',
            nrpe_command  => '/usr/lib/nagios/plugins/check_disk --units GB -w 32 -c 16 -e -l  -r "/var/lib/hadoop/data"',
            contact_group => 'admins,analytics',
        }

        # Make sure that this worker node has NodeManager running in a RUNNING state.
        # Install a custom check command for NodeManager Node-State:
        file { '/usr/local/lib/nagios/plugins/check_hadoop_yarn_node_state':
            source => 'puppet:///modules/profile/hadoop/check_hadoop_yarn_node_state',
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
        nrpe::monitor_service { 'hadoop_yarn_node_state':
            description    => 'YARN NodeManager Node-State',
            nrpe_command   => '/usr/local/lib/nagios/plugins/check_hadoop_yarn_node_state',
            contact_group  => 'admins,analytics',
            retry_interval => 3,
        }

        # Java heap space used alerts.
        # The goal is to get alarms for long running memory leaks like T153951.
        # Only include heap size alerts if heap size is configured.
        $hadoop_datanode_heapsize = $::cdh::hadoop::hadoop_heapsize
        if $hadoop_datanode_heapsize {
            $dn_jvm_warning_threshold  = floor($hadoop_datanode_heapsize * 0.9 * 1000000)
            $dn_jvm_critical_threshold = floor($hadoop_datanode_heapsize * 0.95 * 1000000)
            monitoring::check_prometheus { 'analytics_hadoop_hdfs_datanode':
                description     => 'HDFS DataNode JVM Heap usage',
                dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/analytics-hadoop?panelId=1&fullscreen&orgId=1'],
                query           => "scalar(quantile_over_time(0.5,jvm_memory_bytes_used{hadoop_cluster=\"${cluster_name}\",instance=\"${::hostname}:51010\",area=\"heap\"}[120m]))",
                warning         => $dn_jvm_critical_threshold,
                critical        => $dn_jvm_critical_threshold,
                contact_group   => 'analytics',
                prometheus_url  => "http://prometheus.svc.${::site}.wmnet/analytics",
            }
        }

        $hadoop_nodemanager_heapsize = $::cdh::hadoop::yarn_heapsize
        if $hadoop_nodemanager_heapsize {
            $nm_jvm_warning_threshold  = floor($hadoop_nodemanager_heapsize * 0.9 * 1000000)
            $nm_jvm_critical_threshold = floor($hadoop_nodemanager_heapsize * 0.95 * 1000000)
            monitoring::check_prometheus { 'analytics_hadoop_yarn_nodemanager':
                description     => 'YARN NodeManager JVM Heap usage',
                dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/analytics-hadoop?orgId=1&panelId=17&fullscreen'],
                query           => "scalar(quantile_over_time(0.5,jvm_memory_bytes_used{hadoop_cluster=\"${cluster_name}\",instance=\"${::hostname}:8141\",area=\"heap\"}[120m]))",
                warning         => $nm_jvm_critical_threshold,
                critical        => $nm_jvm_critical_threshold,
                contact_group   => 'analytics',
                prometheus_url  => "http://prometheus.svc.${::site}.wmnet/analytics",
            }
        }
    }
}
