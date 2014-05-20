# sets up the Wikimedia (read-only) IRCd

class ircd::server {

$motd = '
*******************************************************
This is the Wikimedia RC->IRC gateway
*******************************************************
Sending messages to channels is not allowed.

A channel exists for all Wikimedia wikis which have been
changed since the last time the server was restarted. In
general, the name is just the domain name with the .org
left off. For example, the changes on the English Wikipedia
are available at #en.wikipedia

If you want to talk, please join one of the many
Wikimedia-related channels on irc.freenode.net.
'

    file {
        '/usr/local/ircd-ratbox/etc/ircd.conf':
            mode   => '0444',
            owner  => 'irc',
            group  => 'irc',
            source => 'puppet:///private/misc/ircd.conf';
        '/usr/local/ircd-ratbox/etc/ircd.motd':
            mode    => '0444',
            owner   => 'irc',
            group   => 'irc',
            content => $motd;
        '/etc/apache2/sites-available/irc.wikimedia.org':
            mode   => '0444',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///modules/ircd/apache/irc.wikimedia.org';
    }

    # redirect http://irc.wikimedia.org to http://meta.wikimedia.org/wiki/IRC
    apache_site { 'irc': name => 'irc.wikimedia.org' }

    # Doesn't work in Puppet 0.25 due to a bug
    service { 'ircd':
        ensure   => running,
        provider => base,
        binary   => '/usr/local/ircd-ratbox/bin/ircd';
    }

    # Monitoring
    monitor_service { 'ircd':
        description   => 'ircd',
        check_command => 'check_ircd',
    }
}

