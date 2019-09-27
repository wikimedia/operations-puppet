# == Class profile::analytics::cluster::packages::hadoop
#
# Hadoop specific packages that should be installed on analytics computation
# nodes (workers and clients).
# This class probably should not be included on any 'master' type nodes.
#
class profile::analytics::cluster::packages::hadoop {

    include ::profile::analytics::cluster::packages::common

    require_package(
        'python3-kafka',
        'python3-confluent-kafka',
    )
}