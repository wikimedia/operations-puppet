# == Class profile::bigtop::apt
#
# Set Bigtop's apt repository to the host.
# Pins thirdparty/bigtop packages in our apt repo
# to a higher priority than others.  This mainly exists
# because both Debian and Bigtop have versions of zookeeper
# that conflict.  Where this class is included, the
# Bigtop version of zookeeper (and any other conflicting packages)
# will be preferred.
#
# == Args
#  [*pin_release*]
#    Set apt specific pin settings to force packages of the Hadoop distribution
#    to have more priority than the Debian upstream ones.
#    Default: true
#
#  [*component*]
#    Apt component to use for Bigtop.
#    Default: 'bigtop15'
#

class profile::bigtop::apt (
    Boolean $pin_release = lookup('profile::bigtop::apt::pin_release', { 'default_value' => true }),
    String $component = lookup('profile::bigtop::apt::component', { 'default_value' => 'bigtop15' }),
){
    apt::repository { "thirdparty-${component}":
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => "${::lsbdistcodename}-wikimedia",
        components => "thirdparty/${component}",
        notify     => Exec['apt_update_hadoop_component'],
    }

    $ensure_pin = $pin_release ? {
      true  => 'present',
      false => 'absent',
    }

    if $pin_release {
        apt::pin { "thirdparty-${component}":
            ensure   => $ensure_pin,
            pin      => "release c=thirdparty/${component}",
            priority => '1002',
            notify   => Exec['apt_update_hadoop_component'],
        }
    }

    # First installs can trip without this.
    exec {'apt_update_hadoop_component':
        command     => '/usr/bin/apt-get update',
        refreshonly => true,
    }

}
