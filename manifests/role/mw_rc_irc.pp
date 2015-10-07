class role::mw_rc_irc {

    system::role { 'role::mw_rc_irc': description => 'MW Changes IRC Broadcast Server' }

    include passwords::udpmxircecho
    $udpmxircecho_pass = $passwords::udpmxircecho::udpmxircecho_pass

    class { '::mw_rc_irc::irc-echo':
        ircpassword => $udpmxircecho_pass,
    }

    include mw_rc_irc::ircserver
    include mw_rc_irc::apache

    ferm::service { 'ircd_public':
        proto => 'tcp',
        port   => '(6664 6665 6666 6667 6668 6669 8001)',
    }
}
