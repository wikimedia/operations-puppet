# = Class: shinken
# Sets up a shinken monitoring server

class shinken(
    $auth_secret
) {
    include shinken::shinkengen

    package { 'shinken':
        ensure => present,
    }

    package { 'python-cherrypy3':
        ensure => present,
    }

    service { 'shinken':
        ensure => running,
        enable => true,
    }

    file { '/etc/shinken/modules':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        require => Package['shinken'],
    }

    file { '/etc/shinken/modules/webui.cfg':
        ensure  => present,
        content => template('shinken/webui.cfg.erb'),
        owner   => 'root',
        group   => 'root',
        require => File['/etc/shinken/modules'],
        notify  => Service['shinken'],
    }

    file { '/etc/shinken/shinken.cfg':
        ensure  => present,
        source  => 'puppet:///modules/shinken/shinken.cfg',
        owner   => 'root',
        group   => 'root',
        require => Package['shinken'],
        notify  => Service['shinken'],
    }

    file { '/etc/shinken/pollers/poller.cfg':
        ensure  => present,
        source  => 'puppet:///modules/shinken/poller.cfg',
        owner   => 'root',
        group   => 'root',
        require => Package['shinken'],
        notify  => Service['shinken'],
    }

    file { '/etc/shinken/brokers/broker.cfg':
        ensure  => present,
        source  => 'puppet:///modules/shinken/broker.cfg',
        owner   => 'root',
        group   => 'root',
        require => Package['shinken'],
        notify  => Service['shinken'],
    }

    file { '/etc/shinken/templates.cfg':
        ensure  => present,
        source  => 'puppet:///modules/shinken/templates.cfg',
        owner   => 'root',
        group   => 'root',
        require => Package['shinken'],
        notify  => Service['shinken'],
    }

    file { '/etc/shinken/generated':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        require => Package['shinken'],
    }

    file { '/etc/shinken/customconfig':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        require => Package['shinken'],
    }

    class { 'nagios_common::contactgroups':
        source     => 'puppet:///modules/nagios_common/contactgroups-labs.cfg',
        owner      => 'root',
        group      => 'root',
        config_dir => '/etc/shinken',
        require    => Package['shinken'],
        notify     => Service['shinken'],
    }

    class { 'nagios_common::contacts':
        source     => 'puppet:///modules/nagios_common/contacts-labs.cfg',
        owner      => 'root',
        group      => 'root',
        config_dir => '/etc/shinken',
        require    => Package['shinken'],
        notify     => Service['shinken'],
    }

    class { [
      'nagios_common::user_macros',
      'nagios_common::timeperiods',
    ] :
        config_dir => '/etc/shinken',
        owner      => 'root',
        group      => 'root',
        notify     => Service['shinken'],
        require    => Package['shinken'],
    }

    class { 'nagios_common::notification_commands':
        config_dir   => '/etc/shinken',
        owner        => 'root',
        group        => 'root',
        notify       => Service['shinken'],
        require      => Package['shinken'],
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
        owner      => 'root',
        group      => 'root',
        notify     => Service['shinken'],
    }
}
