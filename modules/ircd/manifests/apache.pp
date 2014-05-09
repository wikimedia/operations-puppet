# redirect http://irc.wikimedia.org to http://meta.wikimedia.org/wiki/IRC
class ircd::apache {

    file {
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

    apache_site { 'irc': name => 'irc.wikimedia.org' }
}

