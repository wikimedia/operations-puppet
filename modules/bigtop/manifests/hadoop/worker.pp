# SPDX-License-Identifier: Apache-2.0
# == Class bigtop::hadoop::worker
# Wrapper class for Hadoop Worker node services:
# - DataNode
# - NodeManager (YARN)
#
# This class will attempt to create and manage the required
# local worker directories defined in the $datanode_mounts array.
# You must make sure that the paths defined in $datanode_mounts are
# formatted and mounted properly yourself; This puppet module does not
# manage them.
#
# == Params
#
# [*yarn_use_multi_spark_shufflers*]
#   Boolean: This parameter determines whether or not the host should
#   install the packages containing the spark shuffler. The value is passed
#   verbatim from this wrapper class to the bigtop::hadoop::nodemanager class.
#
# [*yarn_multi_spark_shuffler_versions*]
#   This is a list of major.minor versions of spark shuffler to install.
#   This has no effect if yarn_use_multi_spark_shufflers is false. The value 
#   is passed verbatim from this wrapper class to the bigtop::hadoop::nodemanager
#   class.
#

class bigtop::hadoop::worker (
    Boolean $yarn_use_multi_spark_shufflers                           = false,
    Array[Bigtop::Spark::Version] $yarn_multi_spark_shuffler_versions = [],
) {
    Class['bigtop::hadoop'] -> Class['bigtop::hadoop::worker']

    bigtop::hadoop::worker::paths { $::bigtop::hadoop::datanode_mounts: }

    class { 'bigtop::hadoop::datanode':
        require => Bigtop::Hadoop::Worker::Paths[$::bigtop::hadoop::datanode_mounts],
    }

    # YARN uses NodeManager.
    class { 'bigtop::hadoop::nodemanager':
        require                            => Bigtop::Hadoop::Worker::Paths[$::bigtop::hadoop::datanode_mounts],
        yarn_use_multi_spark_shufflers     => $yarn_use_multi_spark_shufflers,
        yarn_multi_spark_shuffler_versions => $yarn_multi_spark_shuffler_versions,
    }
}
