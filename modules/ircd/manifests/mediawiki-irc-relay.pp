# MediaWiki RecentChanges to IRC relay
# a client on our IRCd that outputs wiki RCs

class ircd::mediawiki-irc-relay {

    include passwords::udpmxircecho

    $udpmxircecho_pass = $passwords::udpmxircecho::udpmxircecho_pass

    system::role { 'ircd::mediawiki-irc-relay': description => 'MediaWiki RC to IRC relay' }

    package { 'python-irclib': ensure => latest; }

    file { '/usr/local/bin/udpmxircecho.py':
        content => template('ircd/udpmxircecho.py.erb'),
        mode    => '0555',
        owner   => 'irc',
        group   => 'irc';
    }

    file { '/etc/init/ircecho.conf':
        source  => 'puppet:///modules/ircd/upstart/ircecho.conf',
        require => File['/usr/local/bin/udpmxircecho.py'],
    }

    # Ensure that the service is running.
    service { 'ircecho':
        ensure => running,
        provider => 'upstart',
        require => File['/etc/init/ircecho.conf'],
    }
}
