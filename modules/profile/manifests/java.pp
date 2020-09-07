#== Class profile::java
#
# This profile takes care of deploying openjdk following the best
# practices used in the WMF.
#
# This profile also takes into account the possibility of deploying various kind
# of openjdk variants (jre, headless-jre, jdk, headless-jdk).
#
# To avoid unnecessary hiera params, we have defaults:
# - On Debian Stretch, we simply deploy openjdk-8-jdk.
# - On Debian Buster, by default, we simply deploy openjdk-11-jdk.
#
# Changing the defaults is very easy, for example we can set the following in hiera
# to deploy openjdk-8-jre-headless, openjdk-11-jdk and set the former as default
# via alternatives:
#
# profile::java::java_packages:
#  - version: 8
#    variant: jre-headless
#  - version: 11
#    variant: jdk
#
# There is also the possibility of adding extra args in /etc/environment.d/10openjdk.conf
# (used by some teams like Analytics).
# Example: 'JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"'
#
# For convenience a variable named "default_java_home" is provided to expose the default
# jvm's home directory.
#
class profile::java (
    Array[Java::PackageInfo] $java_packages = lookup('profile::java::java_packages'),
    Optional[String]         $extra_args    = lookup('profile::java::extra_args'),
    Boolean                  $hardened_tls  = lookup('profile::java::hardened_tls'),
    Java::Egd_source         $egd_source    = lookup('profile::java::egd_source'),
) {

    if os_version('debian == stretch') {
        $default_java_packages = [{'version' => '8', 'variant' => 'jdk'}]
    } else {
        $default_java_packages = [{'version' => '11', 'variant' => 'jdk'}]
    }

    $_java_packages = $java_packages.empty() ? {
        true  => $default_java_packages,
        false => $java_packages
    }

    class { 'java':
        java_packages => $_java_packages,
        hardened_tls  => $hardened_tls,
        egd_source    => $egd_source,
    }

    $default_java_home = $java::java_home

    if $extra_args {

        file { '/etc/environment.d':
            ensure => 'directory',
        }

        file { '/etc/environment.d/10openjdk.conf':
            content => $extra_args,
        }
    }
}
