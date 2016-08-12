# == Class role::analytics_cluster::hadoop::master
# Includes cdh::hadoop::master classes
#
class role::analytics_cluster::hadoop::master {
    system::role { 'analytics_cluster::hadoop::master':
        description => 'Hadoop Master (NameNode & ResourceManager)',
    }

    require role::analytics_cluster::hadoop::client
    include role::analytics_cluster::monitoring::disks

    class { 'cdh::hadoop::master': }

    # Master should run httpfs daemon.
    class { 'cdh::hadoop::httpfs':
        require => Class['cdh::hadoop::master'],
    }

    # Use jmxtrans for sending metrics
    class { 'cdh::hadoop::jmxtrans::master':
        statsd  => hiera('statsd'),
    }

    # This will create HDFS user home directories
    # for all users in the provided groups.
    # This only needs to be run on the NameNode
    # where all users that want to use Hadoop
    # must have shell accounts anyway.
    class { 'cdh::hadoop::users':
        require => Class['cdh::hadoop::master'],
    }

    # We need to include this class somewhere, and the master
    # role is as good as place as any, since we only need it to
    # be included on one node.
    include role::analytics_cluster::mysql_password

    # FairScheduler is creating event logs in hadoop.log.dir/fairscheduler/
    # It rotates them but does not delete old ones.  Set up cronjob to
    # delete old files in this directory.
    cron { 'hadoop-clean-fairscheduler-event-logs':
        command => 'test -d /var/log/hadoop-yarn/fairscheduler && /usr/bin/find /var/log/hadoop-yarn/fairscheduler -type f -mtime +14 -exec rm {} >/dev/null \;',
        minute  => 5,
        hour    => 0,
        require => Class['cdh::hadoop::master'],
    }

    # Include icinga alerts if production realm.
    if $::realm == 'production' {
        # Icinga process alerts for NameNode, ResourceManager and HistoryServer
        nrpe::monitor_service { 'hadoop-hdfs-namenode':
            description   => 'Hadoop Namenode - Primary',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.server.namenode.NameNode"',
            contact_group => 'admins,analytics',
            require       => Class['cdh::hadoop::master'],
            critical      => true,
        }
        nrpe::monitor_service { 'hadoop-hdfs-zkfc':
            description   => 'Hadoop HDFS Zookeeper failover controller',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.hdfs.tools.DFSZKFailoverController"',
            contact_group => 'admins,analytics',
            require       => Class['cdh::hadoop::master'],
        }
        nrpe::monitor_service { 'hadoop-yarn-resourcemanager':
            description   => 'Hadoop ResourceManager',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.yarn.server.resourcemanager.ResourceManager"',
            contact_group => 'admins,analytics',
            require       => Class['cdh::hadoop::master'],
            critical      => true,
        }
        nrpe::monitor_service { 'hadoop-mapreduce-historyserver':
            description   => 'Hadoop HistoryServer',
            nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C java -a "org.apache.hadoop.mapreduce.v2.hs.JobHistoryServer"',
            contact_group => 'admins,analytics',
            require       => Class['cdh::hadoop::master'],
        }

        # Allow nagios to run the check_hdfs_active_namenode as hdfs user.
        sudo::user { 'nagios-check_hdfs_active_namenode':
            user       => 'nagios',
            privileges => ['ALL = NOPASSWD: /usr/local/bin/check_hdfs_active_namenode'],
        }
        # Alert if there is no active NameNode
        nrpe::monitor_service { 'hadoop-hdfs-active-namenode':
            description   => 'At least one Hadoop HDFS NameNode is active',
            nrpe_command  => '/usr/bin/sudo /usr/local/bin/check_hdfs_active_namenode',
            contact_group => 'admins,analytics',
            require       => [
                Class['cdh::hadoop::master'],
                Sudo::User['nagios-check_hdfs_active_namenode'],
            ],
        }
    }

    # Firewall
    include role::analytics_cluster::hadoop::ferm::namenode
    include role::analytics_cluster::hadoop::ferm::resourcemanager
}
