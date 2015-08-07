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

    # Open up port for debugging
    ferm::service{ 'jmxtrans-jmx':
        proto  => 'tcp',
        port   => '2101',
        srange => '$INTERNAL',
    }
}

class role::analytics::spark::standalone::master {
    require role::analytics::spark::standalone
    include cdh::spark::master
}

class role::analytics::spark::standalone::worker {
    require role::analytics::spark::standalone
    include cdh::spark::worker
}
