# Sets up the Wikimedia (read-only) IRCd

# This is a modified ircd server and is not
# suitable for a general ircd deployment

class mw-rc-irc::ircserver {

    file {
        '/usr/etc/ircd.conf':
            mode   => '0444',
            owner  => 'irc',
            group  => 'irc',
            source => 'puppet:///private/misc/ircd.conf';
        '/usr/etc/ircd.motd':
            mode    => '0444',
            owner   => 'irc',
            group   => 'irc',
            content => template('mw-rc-irc/motd.erb');
    }

    service { 'ircd':
        ensure   => running,
        provider => base,
        binary   => '/usr/bin/ircd';
    }

    diamond::collector { 'IRCDStats':
        source   => 'puppet:///modules/mw-rc-irc/monitor/ircd_stats.py',
        settings => {
            method => 'Threaded',
         },
    }

    monitor_service { 'ircd':
        description   => 'ircd',
        check_command => 'check_ircd',
    }
}
