class role::mw-rc-irc {

    system::role { 'role::mw-rc-irc': description => 'MW Changes IRC Broadcast Server' }

    include passwords::udpmxircecho
    $udpmxircecho_pass = $passwords::udpmxircecho::udpmxircecho_pass

    class { '::mw-rc-irc::irc-relay':
        ircpassword => $udpmxircecho_pass,
    }

    include mw-rc-irc::ircserver
}
