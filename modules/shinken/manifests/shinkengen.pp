class shinken::shinkengen {

    include shinken::server

    package { 'python3-shinkengen':
        ensure => latest
    }

    exec { '/usr/bin/shingen':
        require => Package['python3-shinkengen'],
        user    => 'shinken',
        group   => 'shinken',
        notify  => Service['shinken'],
    }
}
