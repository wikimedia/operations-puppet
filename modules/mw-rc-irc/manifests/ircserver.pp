# Sets up the Wikimedia (read-only) IRCd

# This is a modified ircd server and is not
# suitable for a general ircd deployment

class mw-rc-irc::ircserver {

    file { '/usr/etc/ircd.conf':
        mode   => '0444',
        owner  => 'irc',
        group  => 'irc',
        # lint:ignore:puppet_url_without_modules
        source => 'puppet:///private/misc/ircd.conf',
        # lint:endignore
    }

    file { '/usr/etc/ircd.motd':
        mode    => '0444',
        owner   => 'irc',
        group   => 'irc',
        content => template('mw-rc-irc/motd.erb'),
    }

    file { '/etc/init/ircd.conf':
        source  => 'puppet:///modules/mw-rc-irc/upstart/ircd.conf',
    }

    service { 'ircd':
        ensure   => running,
        provider => 'upstart',
        require  => File['/etc/init/ircd.conf'],
    }

    diamond::collector { 'IRCDStats':
        source   => 'puppet:///modules/mw-rc-irc/monitor/ircd_stats.py',
        settings => {
            method => 'Threaded',
        },
    }

    monitoring::service { 'ircd':
        description   => 'ircd',
        check_command => 'check_ircd',
    }
}
