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
class profile::cdh::apt (
    $pin_release = hiera('profile::cdh::apt::pin_release', true),
){
    apt::repository { 'thirdparty-cloudera':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => "${::lsbdistcodename}-wikimedia",
        components => 'thirdparty/cloudera',
    }

    $ensure_pin = $pin_release ? {
      true => 'present',
      false => 'absent',
    }

    if $pin_release {
        apt::pin { 'thirdparty-cloudera':
            ensure   => $ensure_pin,
            pin      => 'release c=thirdparty/cloudera',
            priority => '1002',
        }
    }
}
