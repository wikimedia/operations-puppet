# Class: icinga
#
# Sets up an icinga server, with appropriate config & plugins
# FIXME: A lot of code in here (init script, user setup, logrotate,
# and others) should probably come from the icinga deb package,
# and not from puppet. Investigate and potentially fix this.
# Note that our paging infrastructure (AQL as of 20161101) may need
# an update of it's sender whitelist. And don't forget to do an end-to-end
# test. That is submit a passive check of DOWN for a paging service and confirm
# people get the pages.
class icinga(
    $enable_notifications  = 1,
    $enable_event_handlers = 1,
) {
    # Setup icinga user
    # FIXME: This should be done by the package
    include ::icinga::group

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

    # Setup icinga custom init script
    # FIXME: This should be provided by the package
    file { '/etc/init.d/icinga':
        source  => 'puppet:///modules/icinga/icinga-init.sh',
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
        content => template('icinga/icinga.cfg.erb'),
        owner   => 'icinga',
        group   => 'icinga',
        mode    => '0644',
        require => Package['icinga'],
        notify  => Service['icinga'],
    }

    file { '/etc/icinga/nsca_frack.cfg':
        content => template('icinga/nsca_frack.cfg.erb'),
        owner   => 'icinga',
        group   => 'icinga',
        mode    => '0644',
        require => Package['icinga'],
        notify  => Service['icinga'],
    }

    class { '::nagios_common::contactgroups':
        source  => 'puppet:///modules/nagios_common/contactgroups.cfg',
        require => Package['icinga'],
        notify  => Service['icinga'],
    }

    class { '::nagios_common::contacts':
        content => secret('nagios/contacts.cfg'),
        require => Package['icinga'],
        notify  => Service['icinga'],
    }

    class { [
      '::nagios_common::user_macros',
      '::nagios_common::timeperiods',
      '::nagios_common::notification_commands',
    ] :
        require => Package['icinga'],
        notify  => Service['icinga'],
    }

    # FIXME: This should be in the package?
    logrotate::conf { 'icinga':
        ensure => present,
        source => 'puppet:///modules/icinga/logrotate.conf',
    }

    # Setup all plugins!
    class { '::icinga::plugins':
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
        options => 'size=1024m,uid=icinga,gid=icinga,mode=755',
        require => File['/var/icinga-tmpfs'],
    }
    # Fix the ownerships of some files. This is ugly but will do for now
    file { ['/var/cache/icinga',
            '/var/lib/icinga',
            '/var/lib/icinga/rw',
        ]:
        ensure => directory,
        owner  => 'icinga',
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
    # See Debian Bug 571801
    file { '/var/lib/nagios/rw':
        owner => 'icinga',
        group => 'www-data',
        mode  => '2710', # The sgid bit means new files inherit guid
    }

    # ensure icinga can write logs for ircecho, raid_handler etc.
    file { '/var/log/icinga':
        ensure => 'directory',
        owner  => 'icinga',
        group  => 'adm',
        mode   => '2755',
    }

    # Check that the icinga config is sane
    monitoring::service { 'check_icinga_config':
        description    => 'Check correctness of the icinga configuration',
        check_command  => 'check_icinga_config',
        check_interval => 10,
    }

    # script to schedule host downtimes
    file { '/usr/local/bin/icinga-downtime':
        ensure => present,
        source => 'puppet:///modules/icinga/icinga-downtime.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
    }

    # script to manually send SMS to Icinga contacts (T82937)
    file { '/usr/local/bin/icinga-sms':
        ensure => present,
        source => 'puppet:///modules/icinga/icinga-sms.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
    }

    # Purge unmanaged nagios_host and nagios_services resources
    # This will only happen for non exported resources, that is resources that
    # are declared by the icinga host itself
    resources { 'nagios_host': purge => true, }
    resources { 'nagios_service': purge => true, }
}
