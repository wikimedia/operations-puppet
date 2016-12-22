# == Class role::analytics_cluster::hadoop::ferm::resourcemanager
#
class role::analytics_cluster::hadoop::ferm::resourcemanager {

    ferm::service{ 'hadoop-yarn-resourcemanager-scheduler':
        proto  => 'tcp',
        port   => '8030',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'hadoop-yarn-resourcemanager-tracker':
        proto  => 'tcp',
        port   => '8031',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'hadoop-yarn-resourcemanager':
        proto  => 'tcp',
        port   => '8032',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'hadoop-yarn-resourcemanager-admin':
        proto  => 'tcp',
        port   => '8033',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'hadoop-yarn-resourcemanager-http-ui':
        proto  => 'tcp',
        port   => '8088',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'hadoop-mapreduce-historyserver':
        proto  => 'tcp',
        port   => '10020',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'hadoop-mapreduce-historyserver-admin':
        proto  => 'tcp',
        port   => '10033',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'hadoop-mapreduce-historyserver-http-ui':
        proto  => 'tcp',
        port   => '19888',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'hadoop-yarn-resourcemanager-jmx':
        proto  => 'tcp',
        port   => '9983',
        srange => '$ANALYTICS_NETWORKS',
    }


}

