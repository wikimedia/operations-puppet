# == Class role::analytics_cluster::hadoop::ferm::resourcemanager
#
class role::analytics_cluster::hadoop::ferm::resourcemanager {
    $ferm_srange = '(($ANALYTICS_NETWORKS $DRUID_PUBLIC_HOSTS))',

    ferm::service{ 'hadoop-yarn-resourcemanager-scheduler':
        proto  => 'tcp',
        port   => '8030',
        srange => $ferm_srange,
    }

    ferm::service{ 'hadoop-yarn-resourcemanager-tracker':
        proto  => 'tcp',
        port   => '8031',
        srange => $ferm_srange,
    }

    ferm::service{ 'hadoop-yarn-resourcemanager':
        proto  => 'tcp',
        port   => '8032',
        srange => $ferm_srange,
    }

    ferm::service{ 'hadoop-yarn-resourcemanager-admin':
        proto  => 'tcp',
        port   => '8033',
        srange => $ferm_srange,
    }

    ferm::service{ 'hadoop-yarn-resourcemanager-http-ui':
        proto  => 'tcp',
        port   => '8088',
        srange => $ferm_srange,
    }

    ferm::service{ 'hadoop-mapreduce-historyserver':
        proto  => 'tcp',
        port   => '10020',
        srange => $ferm_srange,
    }

    ferm::service{ 'hadoop-mapreduce-historyserver-admin':
        proto  => 'tcp',
        port   => '10033',
        srange => $ferm_srange,
    }

    ferm::service{ 'hadoop-mapreduce-historyserver-http-ui':
        proto  => 'tcp',
        port   => '19888',
        srange => $ferm_srange,
    }

    ferm::service{ 'hadoop-yarn-resourcemanager-jmx':
        proto  => 'tcp',
        port   => '9983',
        srange => $ferm_srange,
    }
}

