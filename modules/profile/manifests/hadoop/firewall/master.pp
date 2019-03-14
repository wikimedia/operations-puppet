# == Class profile::hadoop::firewall::master
#
# Set of common firewall rules for Hadoop Master nodes (active and standby)
#
class profile::hadoop::firewall::master(
    $analytics_srange       = hiera('profile::hadoop::firewall::master::analytics_srange', '$DOMAIN_NETWORKS'),
    $analytics_druid_srange = hiera('profile::hadoop::firewall::master::analytics_druid_srange', '$DOMAIN_NETWORKS'),
    $hdfs_ssl_enabled       = hiera('profile::hadoop::firewall::master::hdfs::ssl_enabled', false),
    $yarn_ssl_enabled       = hiera('profile::hadoop::firewall::master::yarn::ssl_enabled', false),
    $mapred_ssl_enabled     = hiera('profile::hadoop::firewall::master::mapred::ssl_enabled', false),
) {

    # This port is also used by the HDFS Checkpoint
    # workflow, as described in:
    # https://blog.cloudera.com/blog/2014/03/a-guide-to-checkpointing-in-hadoop/
    # If blocked it can lead to longer restarts for
    # the active NameNode (that needs to reply all the edit log
    # from its last old fsimage) and connect timeouts on the standby Namenode logs
    # (since it periodically tries to establish HTTPS connections).
    $hadoop_hdfs_namenode_http_port = $hdfs_ssl_enabled ? {
        true    => 50470,
        default => 50070,
    }

    $hadoop_yarn_resourcemanager_http_port = $yarn_ssl_enabled ? {
        true    => 8090,
        default => 8088,
    }

    $hadoop_mapreduce_historyserver_http_port = $mapred_ssl_enabled ? {
        true    => 19890,
        default => 19888,
    }

    ferm::service{ 'hadoop-hdfs-namenode':
        proto  => 'tcp',
        port   => '8020',
        srange => $analytics_druid_srange,
    }

    ferm::service{ 'hadoop-hdfs-zkfc':
        proto  => 'tcp',
        port   => '8019',
        srange => $analytics_srange,
    }

    ferm::service{ 'hadoop-hdfs-namenode-http-ui':
        proto  => 'tcp',
        port   => $hadoop_hdfs_namenode_http_port,
        srange => $analytics_srange,
    }

    ferm::service{ 'hadoop-hdfs-namenode-jmx':
        proto  => 'tcp',
        port   => '9980',
        srange => $analytics_srange,
    }

    ferm::service{ 'hadoop-yarn-resourcemanager-scheduler':
        proto  => 'tcp',
        port   => '8030',
        srange => $analytics_srange,
    }

    ferm::service{ 'hadoop-yarn-resourcemanager-tracker':
        proto  => 'tcp',
        port   => '8031',
        srange => $analytics_srange,
    }

    ferm::service{ 'hadoop-yarn-resourcemanager':
        proto  => 'tcp',
        port   => '8032',
        srange => $analytics_druid_srange,
    }

    ferm::service{ 'hadoop-yarn-resourcemanager-admin':
        proto  => 'tcp',
        port   => '8033',
        srange => $analytics_srange,
    }

    ferm::service{ 'hadoop-yarn-resourcemanager-http-ui':
        proto  => 'tcp',
        port   => $hadoop_yarn_resourcemanager_http_port,
        srange => $analytics_srange,
    }

    ferm::service{ 'hadoop-mapreduce-historyserver':
        proto  => 'tcp',
        port   => '10020',
        srange => $analytics_srange,
    }

    ferm::service{ 'hadoop-mapreduce-historyserver-admin':
        proto  => 'tcp',
        port   => '10033',
        srange => $analytics_srange,
    }

    ferm::service{ 'hadoop-mapreduce-historyserver-http-ui':
        proto  => 'tcp',
        port   => $hadoop_mapreduce_historyserver_http_port,
        srange => $analytics_srange,
    }

    ferm::service{ 'hadoop-yarn-resourcemanager-jmx':
        proto  => 'tcp',
        port   => '9983',
        srange => $analytics_srange,
    }
}

