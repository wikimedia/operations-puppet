# == Class: jetty
#
# Installs jetty-runner, an isolated Java servlet container
#
class jetty {
    include ::java::tools

    package { 'default-jre-headless':
        ensure => present,
    }

    package { 'jetty/jetty-runner':
        ensure => present,
        provider => 'trebuchet',
    }
}
