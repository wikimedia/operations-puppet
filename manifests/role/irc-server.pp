class role::ircserver {

    system::role { 'irc::server': description => 'IRC server' }

    include irc::server,
            irc::mediawiki-irc-relay


}
