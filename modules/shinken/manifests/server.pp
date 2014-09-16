# = Class: shinken::server
# Sets up a shinken monitoring server

class shinken::server(
    $auth_secret
) {
    package { 'shinken':
        ensure  => present,
    }

    service { 'shinken':
        ensure => running,
    }

    file { '/etc/shinken/modules':
        ensure => directory,
        owner  => 'shinken',
        group  => 'shinken',
    }

    file { '/etc/shinken/modules/webui.cfg':
        ensure  => present,
        content => template('shinken/webui.cfg.erb'),
        notify  => Service['shinken'],
        owner   => 'shinken',
        group   => 'shinken',
    }

}
