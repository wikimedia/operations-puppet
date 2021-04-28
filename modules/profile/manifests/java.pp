#== Class profile::java
#
# This profile takes care of deploying openjdk following the best
# practices used in the WMF.
#
# This profile also takes into account the possibility of deploying various kind
# of openjdk variants (jre, jre-headless, jdk, jdk-headless).
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
# @param java_packages Array of Java::PackageInfo describing what to install and configure
# @param extra_args A string of extra arguments to use
# @param hardened_tls if true enable a hardened security profile
# @param trust_puppet_ca if true add the puppet ca to the java trust store
# @param enable_dbg Install debug packages (off by default)
class profile::java (
    Array[Java::PackageInfo] $java_packages   = lookup('profile::java::java_packages'),
    Optional[String]         $extra_args      = lookup('profile::java::extra_args'),
    Boolean                  $hardened_tls    = lookup('profile::java::hardened_tls'),
    Java::Egd_source         $egd_source      = lookup('profile::java::egd_source'),
    Boolean                  $trust_puppet_ca = lookup('profile::java::trust_puppet_ca'),
    Boolean                  $enable_dbg      = lookup('profile::java::enable_dbg'),
) {

    $default_java_packages = $facts['os']['distro']['codename'] ? {
        'stretch'   => [{'version' => '8', 'variant' => 'jdk'}],
        'buster'    => [{'version' => '11', 'variant' => 'jdk'}],
        'bullseye'  => [{'version' => '11', 'variant' => 'jdk'}],
        default     => fail("${module_name} doesn't support ${facts['os']['distro']['codename']}")
    }

    $_java_packages = $java_packages.empty() ? {
        true  => $default_java_packages,
        false => $java_packages
    }

    $cacerts_ensure = $trust_puppet_ca ? {
        true    => 'present',
        default => 'absent',
    }
    $cacerts = {
        'wmf:puppetca.pem' => {
            'ensure' => $cacerts_ensure,
            'path'  => $facts['puppet_config']['localcacert'],
        }
    }
    class { 'java':
        java_packages => $_java_packages,
        hardened_tls  => $hardened_tls,
        egd_source    => $egd_source,
        cacerts       => $cacerts,
        enable_dbg    => $enable_dbg,
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
