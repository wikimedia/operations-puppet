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
}
