# == Class role::analytics_cluster::hadoop::ferm::namenode
#
class role::analytics_cluster::hadoop::ferm::namenode {
    ferm::service{ 'hadoop-hdfs-namenode':
        proto  => 'tcp',
        port   => '8020',
        srange => '(($ANALYTICS_NETWORKS $DRUID_PUBLIC_HOSTS))',
    }

    ferm::service{ 'hadoop-hdfs-zkfc':
        proto  => 'tcp',
        port   => '8019',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'hadoop-hdfs-namenode-http-ui':
        proto  => 'tcp',
        port   => '50070',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'hadoop-hdfs-namenode-jmx':
        proto  => 'tcp',
        port   => '9980',
        srange => '$ANALYTICS_NETWORKS',
    }
}
