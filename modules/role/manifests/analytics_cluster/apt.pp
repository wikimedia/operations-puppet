# == Class role::analytics_cluster::apt
#
class role::analytics_cluster::apt {
    apt::repository { 'thirdparty-cloudera':
        uri         => 'http://apt.wikimedia.org/wikimedia',
        dist        => "${::lsbdistcodename}-wikimedia",
        components  => 'thirdparty/cloudera',
    }
}
