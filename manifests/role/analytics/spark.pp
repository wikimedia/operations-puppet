# == Class role::analytics::spark
#
class role::analytics::spark {
    include cdh::spark
}

# == Class role::analytics::spark::standalone
# Configures a spark standalone cluster.
# This runs spark daemons outside of YARN.
# do not include role::analytics::spark
# and role::analytics::spark::standalone on the same node.
class role::analytics::spark::standalone {
    class { 'cdh::spark':
        master_host      => hiera('spark_master_host',      $::fqdn),
        worker_instances => hiera('spark_worker_instances', undef),
        worker_cores     => hiera('spark_worker_cores',     floor($::processorcount / hiera('spark_worker_instances', 1))),
        worker_memory    => hiera('spark_worker_memory',    undef)
    }
}

class role::analytics::spark::standalone::master {
    require role::analytics::spark::standalone
    include cdh::spark::master

    ferm::service{ 'spark-master-web-ui':
        proto  => 'tcp',
        port   => '18080',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'spark-master-rpc':
        proto  => 'tcp',
        port   => '7077',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'spark-rest-server':
        proto  => 'tcp',
        port   => '6066',
        srange => '$ANALYTICS_NETWORKS',
    }
}

class role::analytics::spark::standalone::worker {
    require role::analytics::spark::standalone
    include cdh::spark::worker

    ferm::service{ 'spark-worker-web-ui':
        proto  => 'tcp',
        port   => '18081',
        srange => '$ANALYTICS_NETWORKS',
    }

    ferm::service{ 'spark-worker-rpc':
        proto  => 'tcp',
        port   => '7078',
        srange => '$ANALYTICS_NETWORKS',
    }
}
