# == Class role::analytics::impala::worker
# Installs and configures the impalad server.
#
class role::analytics::impala::worker {
    include role::analytics::impala
    include cdh::impala::worker

    ferm::service { 'impalad':
        proto  => 'tcp',
        port   => '(21000 21050 22000 23000 25000 28000)',
        srange => '$ANALYTICS_NETWORKS',
    }
}
