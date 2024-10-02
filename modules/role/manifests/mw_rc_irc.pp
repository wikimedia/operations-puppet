class role::mw_rc_irc {

    system::role { 'mw_rc_irc': description => 'MW Changes IRC Broadcast Server' }

    include ::profile::base::production
    include ::profile::firewall
    include ::passwords::udpmxircecho
    include ::profile::mw_rc_irc
}
