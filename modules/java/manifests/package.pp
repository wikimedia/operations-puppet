# SPDX-License-Identifier: Apache-2.0
# == define java::package
#
# This define is used as helper for the 'java' class, it shouldn't
# be used alone if possible.
#
# The define takes as parameter the version and then variant of the Java
# package to deploy (like '8' and 'jre-headless' for example) and deploys it
# following the WMF conventions.
#
define java::package(
    Java::PackageInfo $package_info,
    Boolean           $hardened_tls = false,
    Java::Egd_source  $egd_source   = '/dev/random',
) {
    # Hack to work around https://bugs.java.com/bugdatabase/view_bug.do?bug_id=6202721
    $_egd_source = ($egd_source == '/dev/urandom') ? {
        true    => '/dev/./urandom',
        default => $egd_source,
    }

    $package_name = "openjdk-${package_info['version']}-${package_info['variant']}"

    if $package_info['version'] == '8' {
        apt::package_from_component { $package_name:
            component => 'component/jdk8',
            packages  => [$package_name],
        }
    } elsif $package_info['version'] == '21' {
        if debian::codename::eq('bookworm') {
            apt::package_from_component { $package_name:
                component => 'component/jdk21',
                packages  => [$package_name],
            }
        } else {
            fail('Java 21 is only available for Bookworm')
        }
    } else {
        ensure_packages($package_name)
    }

    $security_file_template = "java/java-${package_info['version']}.security.erb"

    # Use a custom java.security on this host, so that we can restrict the allowed
    # certificate's sigalgs.
    if $hardened_tls {
        file { "/etc/java-${package_info['version']}-openjdk/security/java.security":
            content => template($security_file_template),
            require => Package[$package_name],
        }
    }
}
