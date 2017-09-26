# == Class role::analytics_cluster::hadoop::ferm::namenode
#
class role::analytics_cluster::hadoop::ferm::namenode {
    $ferm_srange = '(($ANALYTICS_NETWORKS $DRUID_PUBLIC_HOSTS))',

    ferm::service{ 'hadoop-hdfs-namenode':
        proto  => 'tcp',
        port   => '8020',
        srange => $ferm_srange,
    }

    ferm::service{ 'hadoop-hdfs-zkfc':
        proto  => 'tcp',
        port   => '8019',
        srange => $ferm_srange,
    }

    ferm::service{ 'hadoop-hdfs-namenode-http-ui':
        proto  => 'tcp',
        port   => '50070',
        srange => $ferm_srange,
    }

    ferm::service{ 'hadoop-hdfs-httpfs':
        proto  => 'tcp',
        port   => '14000',
        srange => $ferm_srange,
    }

    ferm::service{ 'hadoop-hdfs-namenode-jmx':
        proto  => 'tcp',
        port   => '9980',
        srange => $ferm_srange,
    }
}
