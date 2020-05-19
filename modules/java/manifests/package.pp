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
) {
    $package_name = "openjdk-${package_info['version']}-${package_info['variant']}"

    if $package_info['version'] == '8' and os_version('debian == buster') {
        apt::package_from_component { $package_name:
            component => 'component/jdk8',
            packages  => [$package_name],
        }
    } else {
        package { $package_name:
            ensure  => 'present',
        }
    }
}