# sets up the Wikimedia (read-only) IRCd

class ircd::server {

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
            content => template('ircd/motd.erb');
        '/etc/apache2/sites-available/irc.wikimedia.org':
            mode   => '0444',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///modules/ircd/apache/irc.wikimedia.org';
    }

    class { 'apache':
      serveradmin  => 'noc@wikimedia.org',
      before      => Apache_site[irc],
    }

    # redirect http://irc.wikimedia.org to http://meta.wikimedia.org/wiki/IRC
    apache_site { 'irc': name => 'irc.wikimedia.org' }

    # Doesn't work in Puppet 0.25 due to a bug
    service { 'ircd':
        ensure   => running,
        provider => base,
        binary   => '/usr/bin/ircd';
    }

    # Monitoring
    monitor_service { 'ircd':
        description   => 'ircd',
        check_command => 'check_ircd',
    }
}

