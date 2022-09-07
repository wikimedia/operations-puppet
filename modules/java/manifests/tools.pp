# == Class: java::tools
#
# This class aims at providing convenience tools to be used on systems where
# java (JRE or JDK) is installed.

class java::tools {

    # NOTE jmap is used, thus requiring a jdk to be installed
    file { '/usr/local/bin/jheapdump':
        ensure => file,
        mode   => '0555',
        source => 'puppet:///modules/java/jheapdump',
    }
}
