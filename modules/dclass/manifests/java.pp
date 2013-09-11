# == Class dclass::java
#
class dclass::java {
    require dclass

    # Used for mobile device classification in Kraken:
    package { ['libdclass-jni', 'libdclass-java']:
      ensure => 'installed',
    }

    # Symlink libdclass* .so into /usr/lib.
    # Our java does not support multiarch.
    file { '/usr/lib/libdclass.so':
        ensure => 'link',
        target => '/usr/lib/x86_64-linux-gnu/libdclass.so.0',
        require => Package['libdclass0'],
    }
    file { '/usr/lib/libdclassjni.so':
        ensure => 'link',
        target => '/usr/lib/x86_64-linux-gnu/jni/libdclassjni.so',
        require => Package['libdclass-jni'],
    }
}