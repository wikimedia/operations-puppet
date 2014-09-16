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
        ensure  => directory,
        owner   => 'shinken',
        group   => 'shinken',
        require => Package['shinken'],
    }

    file { '/etc/shinken/modules/webui.cfg':
        ensure  => present,
        content => template('shinken/webui.cfg.erb'),
        notify  => Service['shinken'],
        owner   => 'shinken',
        group   => 'shinken',
        require => File['/etc/shinken/modules'],
    }

    file { '/etc/shinken/contacts.cfg':
        ensure  => present,
        source  => 'puppet:///files/shinken/contacts.cfg',
        owner   => 'shinken',
        group   => 'shinken',
        require => Package['shinken'],
    }

    file { '/etc/shinken/contactgroups.cfg':
        ensure  => present,
        source  => 'puppet:///files/shinken/contactgroups.cfg',
        owner   => 'shinken',
        group   => 'shinken',
        require => Package['shinken'],
    }
}
