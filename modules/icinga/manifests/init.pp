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

    file { '/etc/icinga/cgi.cfg':
        source  => 'puppet:///modules/icinga/cgi.cfg',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['icinga'],
        notify  => Service['icinga'],
    }

    file { '/etc/icinga/icinga.cfg':
        source => 'puppet:///modules/icinga/icinga.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        require => Package['icinga'],
        notify  => Service['icinga'],
    }

    file { '/etc/icinga/nsca_frack.cfg':
        source => 'puppet:///private/nagios/nsca_frack.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        require => Package['icinga'],
        notify  => Service['icinga'],
    }

    file { '/etc/icinga/contactgroups.cfg':
        source => 'puppet:///modules/icinga/contactgroups.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        require => Package['icinga'],
        notify  => Service['icinga'],
    }

    class { 'nagios_common::contacts':
        source => 'puppet:///private/nagios/contacts.cfg',
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

    # Script to purge resources for non-existent hosts
    file { '/usr/local/sbin/purge-nagios-resources.py':
        source => 'puppet:///modules/icinga/purge-nagios-resources.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # fix permissions on all individual service files
    # FIXME: THis should not be needed *at all*. Should
    # just have everything bet written with 'icinga' as
    # owner, rather than this monstrosity.
    exec { 'fix_nagios_perms':
        command => '/bin/chmod -R a+r /etc/nagios';
    }
    exec { 'fix_icinga_perms':
        command => '/bin/chmod -R a+r /etc/icinga';
    }
    exec { 'fix_icinga_temp_files':
        command => '/bin/chown -R icinga /var/lib/icinga';
    }
    exec { 'fix_nagios_plugins_files':
        command => '/bin/chmod -R a+w /var/lib/nagios';
    }
    exec { 'fix_icinga_command_file':
        command => '/bin/chmod a+rw /var/lib/nagios/rw/nagios.cmd';
    }

    # Misc. icinga files and directories
    # FIXME: This all should be setup by the package as well
    file { '/etc/icinga/conf.d':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/nagios':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/var/cache/icinga':
        ensure => directory,
        owner  => 'icinga',
        group  => 'www-data',
        mode   => '0775',
    }

    file { '/var/lib/nagios/rw':
        ensure => directory,
        owner  => 'icinga',
        group  => 'nagios',
        mode   => '0777',
    }

    file { '/var/lib/icinga':
        ensure => directory,
        owner  => 'icinga',
        group  => 'www-data',
        mode   => '0755',
    }

    file { '/var/log/icinga':
        ensure => directory,
        owner => 'icinga',
        mode => '2757',
    }
    file { '/var/log/icinga/archives':
        ensure => directory,
        owner => 'icinga',
    }
    file { '/var/log/icinga/icinga.log':
        ensure => file,
        owner => 'icinga',
    }
}
