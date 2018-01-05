# == Class profile::hadoop::apt_pin
# Pins thirdparty/cloudera packages in our apt repo
# to a higher priority than others.  This mainly exists
# because both Debian and CDH have versions of zookeeper
# that conflict.  Where this class is included, the
# CDH version of zookeeper (and any other conflicting packages)
# will be prefered.
#
class profile::hadoop::apt_pin {
    apt::pin { 'cloudera':
        pin      => 'release c=thirdparty/cloudera',
        priority => '1001',
        before   => Class['cdh::hadoop'],
    }
}
