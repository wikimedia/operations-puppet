# redirect http://irc.wikimedia.org to http://meta.wikimedia.org/wiki/IRC
class mw-rc-irc::apache {

    file {
        '/etc/apache2/sites-enabled/irc.wikimedia.org':
            mode   => '0444',
            owner  => 'root',
            group  => 'root',
            source => 'puppet:///modules/mw-rc-irc/apache/irc.wikimedia.org';
    }

    class { 'apache':
      serveradmin  => 'noc@wikimedia.org',
      before      => File['/etc/apache2/sites-enabled/irc.wikimedia.org'],
    }

}

