# == Class cdh::hadoop::worker
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
class cdh::hadoop::worker {
    Class['cdh::hadoop'] -> Class['cdh::hadoop::worker']

    cdh::hadoop::worker::paths { $::cdh::hadoop::datanode_mounts: }

    class { 'cdh::hadoop::datanode':
        require => Cdh::Hadoop::Worker::Paths[$::cdh::hadoop::datanode_mounts],
    }

    # YARN uses NodeManager.
    class { 'cdh::hadoop::nodemanager':
        require => Cdh::Hadoop::Worker::Paths[$::cdh::hadoop::datanode_mounts],
    }
}
