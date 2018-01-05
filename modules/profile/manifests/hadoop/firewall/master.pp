# == Class profile::hadoop::firewall::master
#
# Set of common firewall rules for Hadoop Master nodes (active and standby)
#
class profile::hadoop::firewall::master(
    $analytics_srange       = hiera('profile::hadoop::firewall::master::analytics_srange', 'DOMAIN_NETWORKS'),
    $analytics_druid_srange = hiera('profile::hadoop::firewall::master::analytics_druid_srange', 'DOMAIN_NETWORKS'),
) {

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
        port   => '50070',
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
        port   => '8088',
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
        port   => '19888',
        srange => $analytics_srange,
    }

    ferm::service{ 'hadoop-yarn-resourcemanager-jmx':
        proto  => 'tcp',
        port   => '9983',
        srange => $analytics_srange,
    }
}

