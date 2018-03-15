# == Class profile::cdh::apt
#
# Set Cloudera's apt repository to the host.
# Pins thirdparty/cloudera packages in our apt repo
# to a higher priority than others.  This mainly exists
# because both Debian and CDH have versions of zookeeper
# that conflict.  Where this class is included, the
# CDH version of zookeeper (and any other conflicting packages)
# will be prefered.
#
class profile::cdh::apt {
    apt::repository { 'thirdparty-cloudera':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => "${::lsbdistcodename}-wikimedia",
        components => 'thirdparty/cloudera',
    }
    apt::pin { 'thirdparty-cloudera':
        pin      => 'release c=thirdparty/cloudera',
        priority => '1002',
    }
}
