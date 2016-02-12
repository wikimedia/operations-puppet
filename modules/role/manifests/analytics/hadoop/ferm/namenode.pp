# == Class role::analytics::hadoop::ferm::namenode
#
class role::analytics::hadoop::ferm::namenode {
    ferm::service{ 'hadoop-hdfs-namenode':
        proto  => 'tcp',
        port   => '8020',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'hadoop-hdfs-namenode-http-ui':
        proto  => 'tcp',
        port   => '50070',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'hadoop-hdfs-httpfs':
        proto  => 'tcp',
        port   => '14000',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'hadoop-hdfs-namenode-jmx':
        proto  => 'tcp',
        port   => '9980',
        srange => '$ANALYTICS_NETWORKS',
    }
}
