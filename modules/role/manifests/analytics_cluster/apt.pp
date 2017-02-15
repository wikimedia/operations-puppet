# == Class role::analytics_cluster::apt
# Special apt repository configuration for Analytics Cluster nodes.
# This mainly just includes the Wikimedia 'thirdparty/cloudera' component
# that contains mirrored CDH packages.
#
class role::analytics_cluster::apt {
    apt::repository { 'wikimedia-cloudera':
        uri         => 'http://apt.wikimedia.org/wikimedia',
        dist        => "${::lsbdistcodename}-wikimedia",
        components  => 'thirdparty/cloudera'
    }
}
