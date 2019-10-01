class profile::wmcs::dologmsg(
    Stdlib::Host $dologmsg_host = lookup('dologmsg_host', {'default_value' => 'wm-bot2.wm-bot.eqiad.wmflabs'}),
    Stdlib::Port $dologmsg_port = lookup('dologmsg_port', {'default_value' => 64834}),
){
    # dologmsg to send log messages, configured using $dologmsg_* parameters
    file { '/usr/local/bin/dologmsg':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('profile/wmcs/dologmsg.erb'),
    }

    file {'/usr/local/share/man/man1/':
        ensure  => 'directory',
        recurse => true,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
    }

    file { '/usr/local/share/man/man1/dologmsg.1':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/profile/manpages/man/dologmsg.1',
        require => File['/usr/local/share/man/man1/'],
    }
}
