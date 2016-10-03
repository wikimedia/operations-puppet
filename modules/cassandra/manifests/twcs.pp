# == Class: cassandra::twcs
#
# Enable the deploy repository for Cassandra's time-window compaction strategy.
#
# === Usage
# class { '::cassandra::twcs': }
#

class cassandra::twcs(
) {
    require ::cassandra

    scap::target { 'cassandra/twcs':
        deploy_user => 'deploy-service',
        manage_user => true,
    }
}
