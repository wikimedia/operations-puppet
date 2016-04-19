# A basic relay client that accept changes via udp and echo's them to an irc server

class mw_rc_irc::irc_echo(
    $ircpassword,
) {

    package { 'python-irclib': ensure => latest; }

    file { '/usr/local/bin/udpmxircecho.py':
        content => template('mw_rc_irc/udpmxircecho.py.erb'),
        mode    => '0555',
        owner   => 'irc',
        group   => 'irc';
    }

    file { '/etc/init/ircecho.conf':
        source  => 'puppet:///modules/mw_rc_irc/upstart/ircecho.conf',
        require => File['/usr/local/bin/udpmxircecho.py'],
    }

    if os_version('debian >= jessie') {
        $ircecho_provider = 'systemd'
    } else {
        $ircecho_provider = 'upstart'
    }

    # Ensure that the service is running.
    service { 'ircecho':
        ensure   => running,
        provider => $ircecho_provider,
        require  => File['/etc/init/ircecho.conf'],
    }
}
