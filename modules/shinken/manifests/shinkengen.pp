# = Class: shinken::shinkengen
#
# Sets up shinkengen python package to generate hosts & services
# config for Shinken by hittig the wikitech API
#
# FIXME: Also restarts shinkin on each run, even if no config
# files have changed
class shinken::shinkengen {

    include shinken::server

    package { 'python3-shinkengen':
        ensure => latest,
    }

    exec { '/usr/bin/shingen':
        require => Package['python3-shinkengen'],
        user    => 'shinken',
        group   => 'shinken',
        notify  => Service['shinken'],
    }
}
