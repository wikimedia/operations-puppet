# = Class: shinken
# Sets up a shinken monitoring server

class shinken(
    $auth_secret
) {
    include shinken::shinkengen

    package { 'shinken':
        ensure  => present,
    }

    # This is required because default shinken package on trusty
    # has a broken init script. See line 76 of included init script
    file { '/etc/init.d/shinken':
        source  => 'puppet:///modules/shinken/init',
        require => Package['shinken'],
    }

    service { 'shinken':
        ensure  => running,
        require => File['/etc/init.d/shinken'],
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

    file { '/etc/shinken/templates.cfg':
        ensure  => present,
        source  => 'puppet:///modules/shinken/templates.cfg',
        owner   => 'shinken',
        group   => 'shinken',
        require => Package['shinken'],
        notify  => Service['shinken'],
    }

    file { '/etc/shinken/generated':
        ensure  => directory,
        owner   => 'shinken',
        group   => 'shinken',
        require => Package['shinken'],
    }

    file { '/etc/shinken/customconfig':
        ensure  => directory,
        owner   => 'shinken',
        group   => 'shinken',
        require => Package['shinken'],
    }

    class { 'nagios_common::contactgroups':
        source     => 'puppet:///modules/nagios_common/contactgroups-labs.cfg',
        owner      => 'shinken',
        group      => 'shinken',
        config_dir => '/etc/shinken',
        require    => Package['shinken'],
        notify     => Service['shinken'],
    }

    class { 'nagios_common::contacts':
        source     => 'puppet:///modules/nagios_common/contacts-labs.cfg',
        owner      => 'shinken',
        group      => 'shinken',
        config_dir => '/etc/shinken',
        require    => Package['shinken'],
        notify     => Service['shinken'],
    }

    class { [
      'nagios_common::user_macros',
      'nagios_common::timeperiods',
    ] :
        config_dir => '/etc/shinken',
        owner      => 'shinken',
        group      => 'shinken',
        notify     => Service['shinken'],
        require    => Package['shinken'],
    }

    class { 'nagios_common::notification_commands':
        config_dir   => '/etc/shinken',
        owner        => 'shinken',
        group        => 'shinken',
        notify       => Service['shinken'],
        require      => Package['shinken'],
        lover_name   => 'Shinken',
        irc_dir_path => '/var/log/ircecho',
    }

    # Default localhost config, we do not need this
    file { '/etc/shinken/hosts/localhost.cfg':
        ensure  => absent,
        require => Package['shinken'],
        notify  => Service['shinken'],
    }

    # Custom commands we use
    class { 'nagios_common::commands':
        require    => Package['shinken'],
        config_dir => '/etc/shinken',
        owner      => 'shinken',
        group      => 'shinken',
        notify     => Service['shinken'],
    }
}
