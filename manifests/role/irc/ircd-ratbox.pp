class role::irc::ircd-ratbox {
    system::role { 'role::ircd': description => 'IRC Broadcast Server' }
    include ircd::server
}
