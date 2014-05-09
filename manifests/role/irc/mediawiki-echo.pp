class role::irc::mediawiki-echo {

    system::role { 'ircd::mediawiki-irc-echo': description => 'MediaWiki RC to IRC relay' }

    include passwords::udpmxircecho
    $udpmxircecho_pass = $passwords::udpmxircecho::udpmxircecho_pass

    class { 'ircd::mediawiki-irc-relay':
        ircpassword => $udpmxircecho_pass,
    }
}
