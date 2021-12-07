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
    String $cluster_name                  = lookup('profile::hadoop::common::hadoop_cluster_name'),
    Boolean $monitoring_enabled           = lookup('profile::hadoop::worker::monitoring_enabled', { 'default_value' => false }),
    String $ferm_srange                   = lookup('profile::hadoop::worker::ferm_srange', { 'default_value' => '$DOMAIN_NETWORKS' }),
    Boolean $check_mountpoints_disk_space = lookup('profile::hadoop::worker::check_mountpoints_disk_space', { 'default_value' => true }),
) {
    require ::profile::analytics::cluster::packages::common
    require ::profile::hadoop::common
    require ::profile::java

    if $monitoring_enabled {
        # Prometheus exporters
        require ::profile::hadoop::monitoring::datanode
        require ::profile::hadoop::monitoring::nodemanager
    }

    class { '::bigtop::hadoop::worker': }

    # The HDFS journalnodes are co-located for convenience,
    # but it is not a strict requirement.
    if $::fqdn in $::bigtop::hadoop::journalnode_hosts {
        if $monitoring_enabled {
            require profile::hadoop::monitoring::journalnode
        }
        class { 'bigtop::hadoop::journalnode': }
    }


    # This allows Hadoop daemons to talk to each other.
    ferm::service{ 'hadoop-access':
        proto  => 'tcp',
        port   => '1024:65535',
        srange => $ferm_srange,
    }

    # Needed to ease enabling Kerberos and Linux containers
    file { '/usr/local/sbin/set_yarn_dir_ownership':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
        source => 'puppet:///modules/profile/hadoop/worker/set_yarn_dir_ownership',
    }

    if $monitoring_enabled {
        # Icinga process alerts for DataNode and NodeManager
        nrpe::monitor_service { 'hadoop-hdfs-datanode':
            description   => 'Hadoop DataNode',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.server.datanode.DataNode"',
            contact_group => 'admins,analytics',
            require       => Class['bigtop::hadoop::worker'],
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Alerts#HDFS_Datanode_process',
        }
        nrpe::monitor_service { 'hadoop-yarn-nodemanager':
            description   => 'Hadoop NodeManager',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.yarn.server.nodemanager.NodeManager"',
            contact_group => 'admins,analytics',
            require       => Class['bigtop::hadoop::worker'],
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Alerts#Yarn_Nodemanager_process',
        }

        if $::fqdn in $::bigtop::hadoop::journalnode_hosts {
            nrpe::monitor_service { 'hadoop-hdfs-journalnode':
                description   => 'Hadoop JournalNode',
                nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.qjournal.server.JournalNode"',
                contact_group => 'admins,analytics',
                require       => Class['bigtop::hadoop'],
                notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Alerts#HDFS_Journalnode_process',
            }
        }

        if $check_mountpoints_disk_space {
            # Alert on datanode mount disk space.  These mounts are ignored by the
            # base module's check_disk via the base::monitoring::host::nrpe_check_disk_options
            # override in worker.yaml hieradata.
            nrpe::monitor_service { 'disk_space_hadoop_worker':
                description   => 'Disk space on Hadoop worker',
                nrpe_command  => '/usr/lib/nagios/plugins/check_disk --units GB -w 32 -c 16 -e -l  -r "/var/lib/hadoop/data"',
                contact_group => 'admins,analytics',
                notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Administration',
            }
        }
    }
}
