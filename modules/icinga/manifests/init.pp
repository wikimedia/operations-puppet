# Class: icinga
#
# Sets up an icinga server, with appropriate config & plugins
# FIXME: A lot of code in here (init script, user setup, logrotate,
# and others) should probably come from the icinga deb package,
# and not from puppet. Investigate and potentially fix this.
class icinga {
    # Setup icinga user
    # FIXME: This should be done by the package
    include icinga::group

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
        groups     => [ 'nagios' ],
    }

    package { 'icinga':
        ensure => 'present',
    }

    # for nrpe checks to run per T110893
    package { 'libssl0.9.8':
        ensure => present,
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

    file { '/etc/icinga/cgi.cfg':
        source  => 'puppet:///modules/icinga/cgi.cfg',
        owner   => 'icinga',
        group   => 'icinga',
        mode    => '0644',
        require => Package['icinga'],
        notify  => Service['icinga'],
    }

    file { '/etc/icinga/icinga.cfg':
        source  => 'puppet:///modules/icinga/icinga.cfg',
        owner   => 'icinga',
        group   => 'icinga',
        mode    => '0644',
        require => Package['icinga'],
        notify  => Service['icinga'],
    }

    file { '/etc/icinga/nsca_frack.cfg':
        content => secret('nagios/nsca_frack.cfg'),
        owner   => 'icinga',
        group   => 'icinga',
        mode    => '0644',
        require => Package['icinga'],
        notify  => Service['icinga'],
    }

    class { 'nagios_common::contactgroups':
        source => 'puppet:///modules/nagios_common/contactgroups.cfg',
    }

    class { 'nagios_common::contacts':
        content => secret('nagios/contacts.cfg'),
        require => Package['icinga'],
        notify  => Service['icinga'],
    }

    class { [
      'nagios_common::user_macros',
      'nagios_common::timeperiods',
      'nagios_common::notification_commands',
    ] :
        require => Package['icinga'],
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
        require => Package['icinga'],
        notify  => Service['icinga'],
    }

    # Setup tmpfs for use by icinga
    file { '/var/icinga-tmpfs':
        ensure => directory,
        owner  => 'icinga',
        group  => 'icinga',
        mode   => '0755',
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

    # Script to purge resources for non-existent hosts
    file { '/usr/local/sbin/purge-nagios-resources.py':
        source => 'puppet:///modules/icinga/purge-nagios-resources.py',
        owner  => 'icinga',
        group  => 'icinga',
        mode   => '0755',
    }

    # Command folders / files to let icinga web to execute commands
    file { '/var/lib/nagios/rw':
        ensure => directory,
        owner  => 'icinga',
        group  => 'nagios',
        mode   => '0775',
    }

    file { '/var/lib/nagios/rw/nagios.cmd':
        ensure => present,
        owner  => 'icinga',
        group  => 'www-data',
        mode   => '0664',
    }

    # Check that the icinga config is sane
    monitoring::service { 'check_icinga_config':
        description           => 'Check correctness of the icinga configuration',
        check_command         => 'check_icinga_config',
        normal_check_interval => 10,
    }

    # script to schedule host downtimes
    file { '/usr/local/bin/icinga-downtime':
        ensure => present,
        source => 'puppet:///modules/icinga/icinga-downtime',
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
    }

}
