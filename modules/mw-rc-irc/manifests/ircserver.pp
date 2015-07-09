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
        '/etc/init/ircd.conf':
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

    ferm::rule {'ircd_public':
        rule => 'saddr (0.0.0.0/0) proto tcp dport (6664 6665 6666 6667 6668 6669 8001) ACCEPT;',
    }
}
