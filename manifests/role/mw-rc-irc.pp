class role::mw-rc-irc {

    system::role { 'role::mw-rc-irc': description => 'MW Changes IRC Broadcast Server' }

    include passwords::udpmxircecho
    $udpmxircecho_pass = $passwords::udpmxircecho::udpmxircecho_pass

    class { '::mw-rc-irc::irc-echo':
        ircpassword => $udpmxircecho_pass,
    }

    include mw-rc-irc::ircserver
    include mw-rc-irc::apache

    ferm::service { 'ircd_public':
        proto => 'tcp',
        port  => '(6664 6665 6666 6667 6668 6669 8001)',
    }

    ferm::service { 'irc_apache':
        proto => 'tcp',
        port  => '80',
    }
}
