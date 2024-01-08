class profile::toolforge::dologmsg(
    Stdlib::Host $dologmsg_host = lookup('dologmsg_host', {'default_value' => 'wm-bot.wm-bot.wmcloud.org'}),
    Stdlib::Port $dologmsg_port = lookup('dologmsg_port', {'default_value' => 64835}),
){
    # dologmsg to send log messages, configured using $dologmsg_* parameters
    file { '/usr/local/bin/dologmsg':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => epp('profile/wmcs/dologmsg.epp', {
            dologmsg_host => $dologmsg_host,
            dologmsg_port => $dologmsg_port,
        }),
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
