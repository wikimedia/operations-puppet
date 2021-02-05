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
    Boolean $pin_release = lookup('profile::cdh::apt::pin_release', { 'default_value' => true }),
    Optional[String] $bigtop_component = lookup('profile::cdh::apt::bigtop_component', { 'default_value' => 'bigtop15' }),
){

    if $bigtop_component {
        $thirdparty_component_name = $bigtop_component
    } else {
        $thirdparty_component_name = 'cloudera'
    }

    apt::repository { "thirdparty-${thirdparty_component_name}":
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => "${::lsbdistcodename}-wikimedia",
        components => "thirdparty/${thirdparty_component_name}",
        notify     => Exec['apt_update_cdh'],
    }

    $ensure_pin = $pin_release ? {
      true => 'present',
      false => 'absent',
    }

    if $pin_release {
        apt::pin { "thirdparty-${thirdparty_component_name}":
            ensure   => $ensure_pin,
            pin      => "release c=thirdparty/${thirdparty_component_name}",
            priority => '1002',
            notify   => Exec['apt_update_cdh'],
        }
    }

    # First installs can trip without this
    exec {'apt_update_cdh':
        command     => '/usr/bin/apt-get update',
        refreshonly => true,
    }

}
