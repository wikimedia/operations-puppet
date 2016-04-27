# A basic relay client that accept changes via udp and echo's them to an irc server

class mw_rc_irc::irc_echo(
    $ircpassword,
) {

    if os_version('debian >= jessie') {
        require_package('python-irc')
    } else {
        require_package('python-irclib')
    }

    file { '/usr/local/bin/udpmxircecho.py':
        content => template('mw_rc_irc/udpmxircecho.py.erb'),
        mode    => '0555',
        owner   => 'irc',
        group   => 'irc';
    }

    if $::initsystem == 'systemd' {
        $ircecho_provider = 'systemd'

        file { '/etc/systemd/system/ircecho.service':
            source  => 'puppet:///modules/mw_rc_irc/systemd/ircecho.service',
            require => File['/usr/local/bin/udpmxircecho.py'],

        }
    } else {
        $ircecho_provider = 'upstart'

        file { '/etc/init/ircecho.conf':
            source  => 'puppet:///modules/mw_rc_irc/upstart/ircecho.conf',
            require => File['/usr/local/bin/udpmxircecho.py'],
        }
    }

    # Ensure that the service is running.
    service { 'ircecho':
        ensure   => running,
        provider => $ircecho_provider,
        require  => File['/etc/init/ircecho.conf'],
    }
}
