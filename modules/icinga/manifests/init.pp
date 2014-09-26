# Class: icinga
#
# Sets up an icinga server, with appropriate config & plugins
# FIXME: A lot of code in here (init script, user setup, logrotate,
# and others) should probably come from the icinga deb package,
# and not from puppet. Investigate and potentially fix this.
class icinga {
    # Setup icinga user
    # FIXME: This should be done by the package
    include nagios::group
    # FIXME: where does the dialout user group come from?
    # It should be included here somehow

    group { 'icinga':
        ensure => present,
        name   => 'icinga',
    }

    user { 'icinga':
        name       => 'icinga',
        home       => '/home/icinga',
        gid        => 'icinga',
        system     => true,
        managehome => false,
        shell      => '/bin/false',
        require    => [ Group['icinga'], Group['nagios'] ],
        groups     => [ 'dialout', 'nagios' ],
    }

    package { 'icinga':
        ensure => latest,
    }

    # Setup icinga custom init script
    # FIXME: This should be provided by the package
    file { '/etc/init.d/icinga':
        source  => 'puppet:///modules/icinga/icinga-init',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        require => Package['icinga'],
    }

    # Setup tmpfs for use by icinga
    file { '/var/icinga-tmpfs':
        ensure => directory,
        owner => 'icinga',
        group => 'icinga',
        mode => '0755',
    }

    mount { '/var/icinga-tmpfs':
        ensure  => mounted,
        atboot  => true,
        fstype  => 'tmpfs',
        device  => 'none',
        options => 'size=128m,uid=icinga,gid=icinga,mode=755',
        require => File['/var/icinga-tmpfs']
    }

    # FIXME: This should not require explicit setup
    service { 'icinga':
        ensure    => running,
        hasstatus => false,
        restart   => '/etc/init.d/icinga reload',
        require   => [
            Mount['/var/icinga-tmpfs'],
            File['/etc/init.d/icinga'],
        ],
    }

    file { '/etc/icinga/cgi.cfg':
        source  => 'puppet:///modules/icinga/cgi.cfg',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Service['icinga'],
        notify  => Service['icinga'],
    }

    file { '/etc/icinga/icinga.cfg':
        source => 'puppet:///modules/icinga/icinga.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        require => Service['icinga'],
        notify  => Service['icinga'],
    }

    file { '/etc/icinga/nsca_frack.cfg':
        source => 'puppet:///private/nagios/nsca_frack.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        require => Service['icinga'],
        notify  => Service['icinga'],
    }

    file { '/etc/icinga/contactgroups.cfg':
        source => 'puppet:///modules/icinga/contactgroups.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        require => Service['icinga'],
        notify  => Service['icinga'],
    }

    class { 'nagios_common::contacts':
        source => 'puppet:///private/nagios/contacts.cfg',
        require => Service['icinga'],
        notify  => Service['icinga'],
    }

    class { [
      'nagios_common::user_macros',
      'nagios_common::timeperiods',
      'nagios_common::notification_commands',
    ] :
        require => Service['icinga'],
        notify  => Service['icinga'],
    }

    # FIXME: This should be in the package?
    file { '/etc/logrotate.d/icinga':
        ensure => present,
        source => 'puppet:///modules/icinga/logrotate.conf',
        mode   => '0444',
    }

    # Setup all plugins!
    class { 'icinga::plugins':
        require => Service['icinga'],
        notify  => Service['icinga'],
    }
}
