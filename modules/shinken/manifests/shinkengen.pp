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

    file { '/etc/shinkengen.yaml':
        source  => 'puppet:///modules/shinken/shinkengen.yaml',
        owner   => 'shinken',
        group   => 'shinken',
    }

    exec { '/usr/bin/shingen':
        owner   => 'shinken',
        group   => 'shinken',
        require => [Package['python3-shinkengen'], File['/etc/shinkengen.yaml']],
        notify  => Service['shinken'],
    }
}
