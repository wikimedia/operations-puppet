class irc::mediawiki-irc-relay {

    include passwords::udpmxircecho

    $udpmxircecho_pass = $passwords::udpmxircecho::udpmxircecho_pass

    system::role { 'misc::mediawiki-irc-relay': description => 'MediaWiki RC to IRC relay' }

    package { 'python-irclib': ensure => latest; }

    file { '/usr/local/bin/udpmxircecho.py':
        content => template('misc/udpmxircecho.py.erb'),
        mode    => '0555',
        owner   => 'irc',
        group   => 'irc';
    }

    service { 'udpmxircecho':
        ensure   => running,
        provider => base,
        binary   => '/usr/local/bin/udpmxircecho.py',
        start    => '/usr/local/bin/udpmxircecho.py rc-pmtpa ekrem.wikimedia.org';
    }
}

