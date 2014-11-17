# A basic relay client that accept changes via udp and echo's them to an irc server

class mw-rc-irc::irc-echo(
    $ircpassword,
) {

    package { 'python-irclib': ensure => latest; }

    file { '/usr/local/bin/udpmxircecho.py':
        content => template('mw-rc-irc/udpmxircecho.py.erb'),
        mode    => '0555',
        owner   => 'irc',
        group   => 'irc';
    }

    file { '/etc/init/ircecho.conf':
        source  => 'puppet:///modules/mw-rc-irc/upstart/ircecho.conf',
        require => File['/usr/local/bin/udpmxircecho.py'],
    }

    # Ensure that the service is running.
    service { 'ircecho':
        ensure   => running,
        provider => 'upstart',
        require  => File['/etc/init/ircecho.conf'],
    }
}
