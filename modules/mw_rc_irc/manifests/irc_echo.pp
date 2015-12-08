# A basic relay client that accept changes via udp and echo's them to an irc server

class mw_rc_irc::irc_echo(
    $ircpassword,
) {

    if os_version('debian >= jessie') {
        package { 'python-irclib': ensure => latest }
    } else {
        package { 'python-irc': ensure => latest }
    }

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

    # Ensure that the service is running.
    service { 'ircecho':
        ensure   => running,
        provider => 'upstart',
        require  => File['/etc/init/ircecho.conf'],
    }
}
