
class icinga::monitor::configuration::files {

    # For all files dealing with icinga configuration

    require icinga::monitor::packages
    require passwords::nagios::mysql

    $nagios_mysql_check_pass = $passwords::nagios::mysql::mysql_check_pass

    Class['icinga::monitor::configuration::variables'] -> Class['icinga::monitor::configuration::files']

    # Icinga configuration files

    file { '/etc/icinga/cgi.cfg':
        source => 'puppet:///files/icinga/cgi.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file { '/etc/icinga/icinga.cfg':
        source => 'puppet:///files/icinga/icinga.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file { '/etc/icinga/nsca_frack.cfg':
        source => 'puppet:///private/nagios/nsca_frack.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    # TEMP: analytics eqiad cluster manual entries.
    # This has been removed since analytics cluster
    # udp2log instances are now puppetized.
    file { '/etc/icinga/analytics.cfg':
        ensure  => 'absent',
    }

    file { '/etc/icinga/checkcommands.cfg':
        content => template('icinga/checkcommands.cfg.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    file { '/etc/icinga/contactgroups.cfg':
        source => 'puppet:///files/icinga/contactgroups.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file { '/etc/icinga/contacts.cfg':
        source => 'puppet:///private/nagios/contacts.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file { '/etc/icinga/misccommands.cfg':
        source => 'puppet:///files/icinga/misccommands.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file { '/etc/icinga/resource.cfg':
        source => 'puppet:///files/icinga/resource.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file { '/etc/icinga/timeperiods.cfg':
        source => 'puppet:///files/icinga/timeperiods.cfg',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    file { '/etc/init.d/icinga':
        source => 'puppet:///files/icinga/icinga-init',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
}

