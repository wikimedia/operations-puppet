# == Class profile::cdh::apt_pin
#
# Pins thirdparty/cloudera packages in our apt repo
# to a higher priority than others.  This mainly exists
# because both Debian and CDH have versions of zookeeper
# that conflict.  Where this class is included, the
# CDH version of zookeeper (and any other conflicting packages)
# will be prefered.
#
class profile::cdh::apt_pin {
    require ::profile::cdh::apt

    apt::pin { 'thirdparty-cloudera':
        pin      => 'release c=thirdparty/cloudera',
        priority => '1002',
    }
}
