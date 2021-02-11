# == Class profile::bigtop::apt
#
# Set Bigtop's apt repository to the host.
# Pins thirdparty/bigtop packages in our apt repo
# to a higher priority than others.  This mainly exists
# because both Debian and CDH have versions of zookeeper
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
#    Apt component to use. In this case, the default is for Apache Bigtop but
#    'cloudera' can also be used, since we still need to support it for some
#    use cases (like Hue).
#    Default: 'bigtop15'
#

class profile::bigtop::apt (
    Boolean $pin_release = lookup('profile::bigtop::apt::pin_release', { 'default_value' => true }),
    Optional[String] $component = lookup('profile::bigtop::apt::component', { 'default_value' => 'bigtop15' }),
){

    if $component {
        $thirdparty_component_name = $component
    } else {
        $thirdparty_component_name = 'cloudera'
    }

    apt::repository { "thirdparty-${thirdparty_component_name}":
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => "${::lsbdistcodename}-wikimedia",
        components => "thirdparty/${thirdparty_component_name}",
        notify     => Exec['apt_update_hadoop_component'],
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
            notify   => Exec['apt_update_hadoop_component'],
        }
    }

    # First installs can trip without this.
    exec {'apt_update_hadoop_component':
        command     => '/usr/bin/apt-get update',
        refreshonly => true,
    }

}
