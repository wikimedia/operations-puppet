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
        owner   => 'shinken',
        group   => 'shinken',
        require => File['/etc/shinken/modules'],
        notify  => Service['shinken'],
    }

    file { '/etc/shinken/shinken.cfg':
        ensure  => present,
        source  => 'puppet:///modules/shinken/shinken.cfg',
        owner   => 'shinken',
        group   => 'shinken',
        require => Package['shinken'],
        notify  => Service['shinken'],
    }

    file { '/etc/shinken/contacts.cfg':
        ensure  => present,
        source  => 'puppet:///modules/shinken/contacts.cfg',
        owner   => 'shinken',
        group   => 'shinken',
        require => Package['shinken'],
        notify  => Service['shinken'],
    }

    file { '/etc/shinken/contactgroups.cfg':
        ensure  => present,
        source  => 'puppet:///modules/shinken/contactgroups.cfg',
        owner   => 'shinken',
        group   => 'shinken',
        require => Package['shinken'],
        notify  => Service['shinken'],
    }

    # Default localhost config, we do not need this
    file { '/etc/shinken/hosts/localhost.cfg':
        ensure  => absent,
        require => Package['shinken'],
        notify  => Service['shinken'],
    }
}

# = Define: shinken::hosts
# Setup a shinken hosts definition file
# FIXME: Autogenerate hosts definitions later on
define shinken::hosts(
    $name,
    $ensure  = present,
    $source  = undef,
    $content = undef
) {
    file { "/etc/shinken/hosts/$name.cfg":
        ensure  => ensure,
        source  => source,
        content => content,
        owner   => 'shinken',
        group   => 'shinken',
        notify  => Service['shinken'],
        require => Package['shinken']
    }
}
