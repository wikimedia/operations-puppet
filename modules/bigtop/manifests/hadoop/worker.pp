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
class bigtop::hadoop::worker {
    Class['bigtop::hadoop'] -> Class['bigtop::hadoop::worker']

    bigtop::hadoop::worker::paths { $::bigtop::hadoop::datanode_mounts: }

    class { 'bigtop::hadoop::datanode':
        require => Bigtop::Hadoop::Worker::Paths[$::bigtop::hadoop::datanode_mounts],
    }

    # YARN uses NodeManager.
    class { 'bigtop::hadoop::nodemanager':
        require => Bigtop::Hadoop::Worker::Paths[$::bigtop::hadoop::datanode_mounts],
    }
}
