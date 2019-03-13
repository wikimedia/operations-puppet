# == Class: java::security
#
# This class is responsible to configure the java.security
# settings to share among multiple services running Java 8.
# The initial effort was done in T182993 to set a good
# standard for TLS min acceptable parameters/config, but then
# it was extended to other things like Hadoop.
#
class java::security {
    # Use a custom java.security on this host, so that we can restrict the allowed
    # certificate's sigalgs.
    file { '/etc/java-8-openjdk/security/java.security':
        source  => 'puppet:///modules/java/java.security',
        require => Package['openjdk-8-jdk'],
    }
}