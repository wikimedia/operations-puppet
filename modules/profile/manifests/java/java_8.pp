# == Class profile::java::java_8
#
# Installs Java 8 on Debian Buster as well as older releases.
# To get Java 8 on Buster, we must first include apt component/jdk8,
# since Java 8 is not the default Java in Buster. In older releases, it is
# available in default apt components.
#
class profile::java::java_8 {

    # In roles where multiple Java daemons are defined,
    # there might be the chance of duplicate declaration of
    # the openjdk package. We should create a standard/shared
    # way of deploying java across our puppet code base,
    # but for the moment a conditional is sufficient.
    if !defined(Package['openjdk-8-jdk']) {
        if debian::codename::eq('buster') {
            apt::package_from_component { 'openjdk-8':
                component => 'component/jdk8',
                packages  => ['openjdk-8-jdk'],
            }

            alternatives::select { 'java':
                path    => '/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java',
                require => Package['openjdk-8-jdk']
            }
        } else {
            package { 'openjdk-8-jdk':
                ensure  => 'present',
            }
        }
    }

    # Defined here for easy reference by other classes.
    $java_home = '/usr/lib/jvm/java-8-openjdk-amd64'
}
