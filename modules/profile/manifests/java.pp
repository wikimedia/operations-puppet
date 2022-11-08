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
# @param extra_args A dict of extra arguments to use
# @param hardened_tls if true enable a hardened security profile
# @param egd_source securerandom source location
# @param trust_puppet_ca if true add the puppet ca to the java trust store
# @param enable_dbg Install debug packages (off by default)
class profile::java (
    Array[Java::PackageInfo]   $java_packages   = lookup('profile::java::java_packages'),
    Hash[String[1], String[1]] $extra_args      = lookup('profile::java::extra_args'),
    Boolean                    $hardened_tls    = lookup('profile::java::hardened_tls'),
    Java::Egd_source           $egd_source      = lookup('profile::java::egd_source'),
    Boolean                    $trust_puppet_ca = lookup('profile::java::trust_puppet_ca'),
    Boolean                    $enable_dbg      = lookup('profile::java::enable_dbg'),
) {

    $default_java_packages = $facts['os']['distro']['codename'] ? {
        'stretch'   => [{'version' => '8', 'variant' => 'jdk'}],
        'buster'    => [{'version' => '11', 'variant' => 'jdk'}],
        'bullseye'  => [{'version' => '11', 'variant' => 'jdk'}],
        'bookworm'  => [{'version' => '17', 'variant' => 'jdk'}],
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

    if $::realm == 'production' {
        $cacerts = {
            'wmf:puppetca.pem' => {
                'ensure' => $cacerts_ensure,
                'path'  => '/usr/share/ca-certificates/wikimedia/Puppet_Internal_CA.crt',
            },
            'wmf:Wikimedia_Internal_Root_CA' => {
                'ensure' => $cacerts_ensure,
                'path'   => '/usr/share/ca-certificates/wikimedia/Wikimedia_Internal_Root_CA.crt',
            },
        }
        $java_require = Package['wmf-certificates']
    } else {
        $cacerts = {
            'wmf:puppetca.pem' => {
                'ensure' => $cacerts_ensure,
                'path'   => $facts['puppet_config']['localcacert'],
            },
        }
        $java_require = undef
    }
    class { 'java':
        java_packages => $_java_packages,
        hardened_tls  => $hardened_tls,
        egd_source    => $egd_source,
        enable_dbg    => $enable_dbg,
        require       => $java_require,
    }
    $cacerts.each |$title, $config| {
        java::cacert {$title:
            require => Alternatives::Java[$java::default_java_package['version']],
            *       => $config,
        }
    }


    $default_java_home = $java::java_home
    $default_package_name = "openjdk-${java::default_java_package['version']}-${java::default_java_package['variant']}"

    unless $extra_args.empty {
        systemd::environment { 'openjdk':
            priority  => 10,
            variables => $extra_args,
        }
    }
}
