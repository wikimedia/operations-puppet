# == Class: jetty
#
# Installs jetty-runner, an isolated Java servlet container
#
class jetty {
    include ::java::tools

    package { 'default-jre-headless':
        ensure => present,
    }

    #package { 'jetty/jetty-runner':
    #    ensure => present,
    #    provider => 'trebuchet',
    #}

    # While a wip...
    ::git::clone { 'jetty-runner':
        directory => '/srv/deployment/jetty',
        origin    => 'https://github.com/MaxSem/jetty-runner-bin.git',
    }
}
