class role::ircd {

    system::role { 'role::ircd': description => 'IRC server' }

    include ircd::server,
            ircd::mediawiki-irc-relay


}
